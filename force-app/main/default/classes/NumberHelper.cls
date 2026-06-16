public with sharing class NumberHelper {
    public class CustomException extends Exception {}
    /**
    *
    * Returns parameter value or 0 if parameter is null
    * !!! NOTE THAT YOU HAVE TO CONVERT THE FUNCTION'S RETURN TYPE MANUALLY !!!
    *
    * @param    value   {Decimal}   Value to check
    *
    */
    public static Object getNumberNullSafe(Object value) {
        return value == null ? 0 : value;
    }

    /**
    * @description This method is for converting null safe number to the integer number
    * @param Integer - value to convert
    * @return Integer converted number
    */
    public static Integer toNumber(Integer value) {
        return (Integer) getNumberNullSafe(value);
    }

    /**
    * @description This method is for converting null safe number to the decimal number
    * @param Decimal - value to convert
    * @return Decimal converted number
    */
    public static Decimal toNumber(Decimal value) {
        return (Decimal) getNumberNullSafe(value);
    }

    /**
    * @description This method is for converting null safe number to the currency value
    * @param Decimal - value to convert
    * @return Decimal converted currency value
    */
    public static Decimal roundCurrency(Decimal value) {
        return roundCurrency(value, 2, RoundingMode.HALF_UP);
    }

    /**
    * @description This method is for converting null safe number to the currency value with scaling
    * @param Decimal - value to convert
    * @param Integer - specified number of scaling. The value of scale must be between –33 and 33
    * @return Decimal converted and scaled currency value
    */
    public static Decimal roundCurrency(Decimal value, Integer scale) {
        return roundCurrency(value, scale, RoundingMode.HALF_UP);
    }

    /**
    * @description This method is for converting null safe number to the currency value with rounding
    * @param Decimal - value to convert
    * @param System.RoundingMode - specified rounding mode for scaling
    * @return Decimal converted and rounded currency value
    */
    public static Decimal roundCurrency(Decimal value, RoundingMode roundingMode) {
        return roundCurrency(value, 2, roundingMode);
    }

    /**
    * @description This method is for converting null safe number to the currency value with scaling and rounding
    * @param Decimal - value to convert
    * @param Integer - specified number of scaling. The value of scale must be between –33 and 33
    * @param System.RoundingMode - specified rounding mode for scaling
    * @return Decimal converted, scaled and rounded currency value
    */
    public static Decimal roundCurrency(Decimal value, Integer scale, RoundingMode roundingMode) {
        return toNumber(value).setScale(scale, roundingMode);
    }

    /**
        * Returns a random number between min (inclusive) and max (exclusive)
    */
    public static Integer getRandomNumberInRange(Integer min, Integer max) {
        if(min == null) {
            throw new CustomException('Minimum value of range is not populated');
        }
        if(max == null) {
            throw new CustomException('Maximum value of range is not populated');
        }
        return (Math.random() * (max - min) + min).intValue();
    }

    /**
    * Returns scale of decimal or one of scale boundaries
    */
    public static Integer getBoundedScale(Decimal val, Integer minScale, Integer maxScale) {
        Integer scale = stripTrailingZeros(val).scale();
        if (scale < minScale) {
            return minScale;
        } else if (scale > maxScale) {
            return maxScale;
        } else {
            return scale;
        }
    }

    /**
    * This is the fix for incorrect work of stripTrailingZeros() for '0.00'-like decimals.
    */
    public static Decimal stripTrailingZeros(Decimal value) {
        if (value == 0) {
            return value.setScale(0);
        } else {
            return value.stripTrailingZeros();
        }
    }
}