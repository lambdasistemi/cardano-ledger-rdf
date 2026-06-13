{- |
Module      : Cardano.Tx.Bech32
Description : Minimal Bech32 codec for Cardano address bytes.
License     : Apache-2.0

Internal Bech32 codec used by the pure transaction RDF core. It covers
the BIP-0173 checksum and bit-conversion surface needed for Cardano
address literals without depending on the @bech32@ package.
-}
module Cardano.Tx.Bech32 (
    decodeBech32Bytes,
    encodeBech32Text,
) where

import Data.Bits (shiftL, shiftR, testBit, xor, (.&.), (.|.))
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.Char (ord, toLower)
import Data.Maybe (mapMaybe)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Word (Word8)

-- | Decode a Bech32 string to its payload bytes.
decodeBech32Bytes :: Text -> Either String ByteString
decodeBech32Bytes raw =
    let input = Text.map toLower raw
        (hrp, rest0) = Text.breakOnEnd "1" input
     in if Text.null hrp
            then Left "bech32 decode failed: StringToDecodeMissingSeparatorChar"
            else do
                let hrpText = Text.dropEnd 1 hrp
                    dataText = rest0
                values <- decodeDataPart dataText
                if length values < checksumLength
                    then Left "bech32 decode failed: DataPartTooShort"
                    else
                        if polymod (hrpExpand hrpText <> values) /= 1
                            then Left "bech32 decode failed: InvalidChecksum"
                            else case convertBits False 5 8 (take (length values - checksumLength) values) of
                                Nothing -> Left "bech32 data-part not byte-aligned"
                                Just bytes -> Right (BS.pack bytes)

-- | Encode bytes as a Bech32 string under the supplied human-readable part.
encodeBech32Text :: Text -> ByteString -> Text
encodeBech32Text hrp bytes =
    let dataValues = convertBitsPadded 8 5 (map fromIntegral (BS.unpack bytes))
        checksum = createChecksum hrp dataValues
     in Text.concat
            [ Text.map toLower hrp
            , "1"
            , Text.pack (map encodeValue (dataValues <> checksum))
            ]

checksumLength :: Int
checksumLength = 6

charset :: String
charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

decodeDataPart :: Text -> Either String [Int]
decodeDataPart txt =
    let chars = Text.unpack txt
        values = traverse decodeValue chars
     in case values of
            Nothing -> Left "bech32 decode failed: InvalidDataPart"
            Just xs -> Right xs

decodeValue :: Char -> Maybe Int
decodeValue c =
    lookup c (zip charset [0 .. 31])

encodeValue :: Int -> Char
encodeValue n =
    charset !! n

hrpExpand :: Text -> [Int]
hrpExpand hrp =
    let chars = Text.unpack hrp
     in map ((`shiftR` 5) . ord) chars
            <> [0]
            <> map ((.&. 31) . ord) chars

polymod :: [Int] -> Int
polymod =
    foldl' step 1
  where
    generators =
        [ 0x3b6a57b2
        , 0x26508e6d
        , 0x1ea119fa
        , 0x3d4233dd
        , 0x2a1462b3
        ]
    step chk value =
        let top = chk `shiftR` 25
            chk0 = ((chk .&. 0x1ffffff) `shiftL` 5) `xor` value
         in foldl'
                ( \acc (i, generator) ->
                    if testBit top i then acc `xor` generator else acc
                )
                chk0
                (zip [0 ..] generators)

createChecksum :: Text -> [Int] -> [Int]
createChecksum hrp values =
    let modValue = polymod (hrpExpand (Text.map toLower hrp) <> values <> replicate checksumLength 0) `xor` 1
     in [ (modValue `shiftR` (5 * (5 - i))) .&. 31
        | i <- [0 .. 5]
        ]

convertBitsPadded :: Int -> Int -> [Int] -> [Int]
convertBitsPadded fromBits toBits input =
    let maxValue = (1 `shiftL` toBits) - 1
        (acc, bits, output) = foldl' (convertStep fromBits toBits maxValue) (0, 0, []) input
     in reverse $
            if bits > 0
                then ((acc `shiftL` (toBits - bits)) .&. maxValue) : output
                else output

convertBits :: Bool -> Int -> Int -> [Int] -> Maybe [Word8]
convertBits pad fromBits toBits input =
    let maxValue = (1 `shiftL` toBits) - 1
        (acc, bits, output) = foldl' (convertStep fromBits toBits maxValue) (0, 0, []) input
        padded =
            if pad && bits > 0
                then ((acc `shiftL` (toBits - bits)) .&. maxValue) : output
                else output
        valid =
            pad
                || bits < fromBits
                    && ((acc `shiftL` (toBits - bits)) .&. maxValue) == 0
     in if valid
            then Just (mapMaybe intToWord8 (reverse padded))
            else Nothing

convertStep :: Int -> Int -> Int -> (Int, Int, [Int]) -> Int -> (Int, Int, [Int])
convertStep fromBits toBits maxValue (acc0, bits0, output0) value =
    emit acc1 bits1 output0
  where
    maxAcc = (1 `shiftL` (fromBits + toBits - 1)) - 1
    acc1 = ((acc0 `shiftL` fromBits) .|. value) .&. maxAcc
    bits1 = bits0 + fromBits
    emit acc bits output
        | bits >= toBits =
            let bits' = bits - toBits
                next = (acc `shiftR` bits') .&. maxValue
             in emit acc bits' (next : output)
        | otherwise = (acc, bits, output)

intToWord8 :: Int -> Maybe Word8
intToWord8 n
    | n >= 0 && n <= 255 = Just (fromIntegral n)
    | otherwise = Nothing
