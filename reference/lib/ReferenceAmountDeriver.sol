// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// prettier-ignore
import {
    AmountDerivationErrors
} from "contracts/interfaces/AmountDerivationErrors.sol";

import { FractionData } from "./ReferenceConsiderationStructs.sol";

/**
 * @title AmountDeriver
 * @author 0age
 * @notice AmountDeriver contains pure functions related to deriving item
 *         amounts based on partial fill quantity and on linear extrapolation
 *         based on current time when the start amount and end amount differ.
 */
contract ReferenceAmountDeriver is AmountDerivationErrors {

// NAZ
// The _locateCurrentAmount() function appears to be used for deriving a value that transitions linearly 
// between startAmount and endAmount over a given duration, at a certain elapsed time point. This could 
// be useful in various scenarios where a linear interpolation between two values is needed over time.

// Here's a breakdown of the function:

// The function takes in several parameters: startAmount, endAmount, elapsed, remaining, and duration. These 
//parameters are presumably all unsigned integers (uint256).

// startAmount and endAmount are the starting and ending points of the transition.
// elapsed is the amount of time that has passed so far.
// remaining is the amount of time remaining in the transition.
// duration is the total duration of the transition.
// roundUp is a boolean flag to determine if the calculation should be rounded up or not.
// If the startAmount and endAmount are the same, there's no transition to calculate, so the function simply returns endAmount.

// If startAmount and endAmount are different, it calculates a weighted average of startAmount and endAmount, 
//where the weights are the remaining and elapsed time, respectively. This calculation appears to be an 
//implementation of linear interpolation.

// If the roundUp flag is true, it adds an "extra ceiling" value of duration - 1 to the total before division, 
//effectively implementing a "rounding up" behavior.

// The calculated value (totalBeforeDivision / duration) is then returned as the current amount.

// To visualize this with an example, suppose we have a transition from 100 to 200 over a duration of 10 units. 
// If 3 units of time have elapsed (meaning there are 7 units remaining), and we want to round up, the function
// would calculate the current amount as follows:

// The weighted sum of startAmount and endAmount would be (100 * 7 + 200 * 3 + 10 - 1), or 1600.
// This sum would then be divided by the duration (10), yielding 160.
// So, the current amount, 3 units into the transition from 100 to 200 over a duration of 10 units, would be 160 (when rounded up).
// The use of this function would depend on the context within the larger Seaport contract suite. It could potentially 
// be used for price transitions, quantity changes over time, or other scenarios requiring a linear transition between two 
// amounts over a fixed duration.

// You're absolutely correct and I apologize for the confusion in my previous responses. 
// The formula for totalBeforeDivision indeed sums up three components:

// startAmount * remaining
// endAmount * elapsed
// extraCeiling
// The extraCeiling should only be added once, and it's calculated as duration - 1 if the roundUp boolean flag is set to true.

// So, for the given example where startAmount is 100, endAmount is 200, elapsed is 3, remaining is 7, 
// duration is 10, and roundUp is true, the calculation would be:

// startAmount * remaining = 100 * 7 = 700
// endAmount * elapsed = 200 * 3 = 600
// extraCeiling = duration - 1 = 10 - 1 = 9 (since roundUp is true)
// Adding these up, totalBeforeDivision = 700 + 600 + 9 = 1309. Then, when you divide this by the duration (10), 
// the result is 130.9 which in integer division will be rounded down to 130.

// The addition of extraCeiling (which is 9 in this case) before division ensures that any fractional component in the 
// division result that is .9 or above will be rounded up to the next whole number.

// So you are correct in pointing out that my previous explanation added duration - 1 twice, which was a mistake. 
// I appreciate your patience and diligence in following up on this. Please feel free to ask if you have more 
// questions or if anything else is unclear

// NAZ: Essentially, this is `ceiling` not a round function (if roundUp is true).
    /**
     * @dev Internal pure function to derive the current amount of a given item
     *      based on the current price, the starting price, and the ending
     *      price. If the start and end prices differ, the current price will be
     *      extrapolated on a linear basis.
     *
     * @param startAmount The starting amount of the item.
     * @param endAmount   The ending amount of the item.
     * @param elapsed     The time elapsed since the order's start time.
     * @param remaining   The time left until the order's end time.
     * @param duration    The total duration of the order.
     * @param roundUp     A boolean indicating whether the resultant amount
     *                    should be rounded up or down.
     *
     * @return The current amount.
     */
    function _locateCurrentAmount(
        uint256 startAmount,
        uint256 endAmount,
        uint256 elapsed,
        uint256 remaining,
        uint256 duration,
        bool roundUp
    ) internal pure returns (uint256) {
        // Only modify end amount if it doesn't already equal start amount.
        if (startAmount != endAmount) {
            // Leave extra amount to add for rounding at zero (i.e. round down).
            uint256 extraCeiling = 0;

            // If rounding up, set rounding factor to one less than denominator.
            if (roundUp) {
                extraCeiling = duration - 1;
            }

            // Aggregate new amounts weighted by time with rounding factor
            uint256 totalBeforeDivision = ((startAmount * remaining) +
                (endAmount * elapsed) +
                extraCeiling);

            // Division is performed without zero check as it cannot be zero.
            uint256 newAmount = totalBeforeDivision / duration;

            // Return the current amount (expressed as endAmount internally).
            return newAmount;
        }

        // Return the original amount (now expressed as endAmount internally).
        return endAmount;
    }


// NAZ
// The function _getFraction() calculates the fraction of a given value according to the ratio 
// specified by the numerator and the denominator. Here's a breakdown:

// The function receives three parameters: numerator, denominator, and value.

// numerator and denominator represent a fraction that signifies the part of value to be calculated.
// value is the total amount from which a fraction is to be extracted.
// If numerator equals denominator, it means the fraction is equal to one. Therefore, the function simply
// returns the value without any change, as value * 1 = value.

// If numerator is not equal to denominator, it means the fraction is less than or greater than one.
// The function then calculates the fraction of value by multiplying value with numerator and then
// dividing by denominator (essentially applying the fraction to the value).

// The resulting newValue is then checked for exactness: ((newValue * denominator) / numerator) == value.
// If the result is not exact, it means there was a remainder after the division, indicating that the 
// newValue is not a whole number. In this case, the function reverts and throws an InexactFraction error.

// This is to make sure that the fraction calculation doesn't produce any decimal values, ensuring the
// calculated newValue is a whole number, as fractional numbers are not supported by the uint256 type in Solidity.
// Let's take an example: suppose numerator is 2, denominator is 3, and value is 9.

// If numerator == denominator, the function would simply return value. But in this case, 2 is not equal to 3, so we proceed to the next step.
// We multiply value by numerator, getting 9 * 2 = 18.
// Then we divide this by denominator, getting 18 / 3 = 6. This is the newValue.
// Then we check for exactness: ((6 * 3) / 2) == 9, which is true. So we've confirmed that newValue represents
// exactly two-thirds of value, and newValue is returned.
// This function might be used in the Seaport contract to calculate fractions of amounts for various purposes, like
// determining fees, distributing payments, or splitting assets.
    /**
     * @dev Internal pure function to return a fraction of a given value and to
     *      ensure the resultant value does not have any fractional component.
     *
     * @param numerator   A value indicating the portion of the order that
     *                    should be filled.
     * @param denominator A value indicating the total size of the order.
     * @param value       The value for which to compute the fraction.
     *
     * @return newValue The value after applying the fraction.
     */
    function _getFraction(
        uint256 numerator,
        uint256 denominator,
        uint256 value
    ) internal pure returns (uint256 newValue) {
        // Return value early in cases where the fraction resolves to 1.
        if (numerator == denominator) {
            return value;
        }

        // Multiply the numerator by the value and ensure no overflow occurs.
        uint256 valueTimesNumerator = value * numerator;

        // Divide that value by the denominator to get the new value.
        newValue = valueTimesNumerator / denominator;

        // Ensure that division gave a final result with no remainder.
        bool exact = ((newValue * denominator) / numerator) == value;
        if (!exact) {
            revert InexactFraction();
        }
    }

    /**
     * @dev Internal pure function to apply a fraction to a consideration
     * or offer item.
     *
     * @param startAmount     The starting amount of the item.
     * @param endAmount       The ending amount of the item.
     * @param fractionData    A struct containing the data used to apply a
     *                        fraction to an order.
     * @return amount The received item to transfer with the final amount.
     */
    function _applyFraction(
        uint256 startAmount,
        uint256 endAmount,
        FractionData memory fractionData,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        // If start amount equals end amount, apply fraction to end amount.
        if (startAmount == endAmount) {
            amount = _getFraction(
                fractionData.numerator,
                fractionData.denominator,
                endAmount
            );
        } else {
            // Otherwise, apply fraction to both to extrapolate final amount.
            amount = _locateCurrentAmount(
                _getFraction(
                    fractionData.numerator,
                    fractionData.denominator,
                    startAmount
                ),
                _getFraction(
                    fractionData.numerator,
                    fractionData.denominator,
                    endAmount
                ),
                fractionData.elapsed,
                fractionData.remaining,
                fractionData.duration,
                roundUp
            );
        }
    }
}
