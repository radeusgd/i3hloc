module Blocks.Time where

import Control.Monad.State
import Data.Time.Clock
import Data.Time.LocalTime
import Data.Dates( dayToDateTime
                 , day
                 , month
                 , year
                 , dateWeekDay
                 )

twoDigitFront :: String -> String
twoDigitFront s | null s        = "00"
                | length s == 1 = '0':s
                | otherwise     = take 2 s

twoDigitBack :: String -> String
twoDigitBack s | null s        = "00"
               | length s == 1 = ['0', last s]
               | otherwise     = drop (length s - 2) s

data Seq = Separator String
         | Sec
         | Minute
         | Hour24
         | Hour12
         | Day
         | Month
         | Year
         | WeekDayFull
         | WeekDayShort
         | AmPm
         | CenturyYear

extractSeq :: Seq -> LocalTime -> String
extractSeq s t =
  let timeOfDay = localTimeOfDay t
      dateTime = dayToDateTime (localDay t)
  in case s of
    Sec ->  twoDigitFront . takeWhile (/= '.') . show $ todSec timeOfDay
    Minute ->  twoDigitFront . show $ todMin timeOfDay
    Hour24 ->  twoDigitFront . show $ todHour timeOfDay
    Hour12 ->  twoDigitFront . show $ todHour timeOfDay `mod` 12
    AmPm -> if todHour timeOfDay < 12 then "am" else "pm"
    Day ->  twoDigitFront . show $ day dateTime
    Month ->  twoDigitFront . show $ month dateTime
    Year ->  show $ year dateTime
    WeekDayFull ->  show $ dateWeekDay dateTime
    WeekDayShort -> take 3 $ show $ dateWeekDay dateTime
    CenturyYear -> twoDigitBack . show $ year dateTime `mod` 100
    Separator se -> se

readSeq :: Char -> Maybe Seq
readSeq s = case s of
  's' -> Just Sec
  'm' -> Just Minute
  'h' -> Just Hour12
  'H' -> Just Hour24
  'd' -> Just Day
  'M' -> Just Month
  'Y' -> Just Year
  'y' -> Just CenturyYear
  'W' -> Just WeekDayFull
  'w' -> Just WeekDayShort
  'a' -> Just AmPm
  _ -> Nothing

getTime :: [Seq] -> IO String
getTime format = do
  utcTime <- getCurrentTime
  timeZone <- getCurrentTimeZone
  let time = utcToLocalTime timeZone utcTime
  return $ flip evalState ("" :: String) $ do
    l <- forM format $ \s -> return (extractSeq s time)
    return $ concat l

