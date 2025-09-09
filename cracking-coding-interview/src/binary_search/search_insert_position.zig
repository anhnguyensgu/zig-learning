// Given a sorted array of distinct integers and a target value, return the index if the target is found. If not, return the index where it would be if it were inserted in order.
//
// You must write an algorithm with O(log n) runtime complexity.
//
//
//
// Example 1:
//
// Input: nums = [1,3,5,6], target = 5
// Output: 2
// Example 2:
//
// Input: nums = [1,3,5,6], target = 2
// Output: 1
// Example 3:
//
// Input: nums = [1,3,5,6], target = 7
// Output: 4
//
//
// Constraints:
//
// 1 <= nums.length <= 104
// -104 <= nums[i] <= 104
// nums contains distinct values sorted in ascending order.
// -104 <= target <= 104
const std = @import("std");

fn searchInsert(nums: []i32, target: i32) i32 {
    if (nums.len == 0) {
        return 0;
    }
    var left: usize = 0;
    var right = nums.len;
    while (left < right) {
        const mid = left + (right - left) / 2;
        if (nums[mid] < target) {
            left = mid + 1;
        } else {
            right = mid;
        }
    }
    return @intCast(left);
}

test "search insert position" {
    var nums = [_]i32{ 1, 3, 5, 6 };

    var target: i32 = 0;
    var result: i32 = -1;

    target = 1;
    result = searchInsert(nums[0..], target);
    try std.testing.expect(result == 0);

    target = 3;
    result = searchInsert(nums[0..], target);
    try std.testing.expect(result == 1);

    target = 5;
    result = searchInsert(nums[0..], target);
    try std.testing.expect(result == 2);

    target = 6;
    result = searchInsert(nums[0..], target);
    try std.testing.expect(result == 3);

    target = 0;
    result = searchInsert(nums[0..], target);
    try std.testing.expect(result == 0);

    target = 2;
    result = searchInsert(nums[0..], target);
    try std.testing.expect(result == 1);

    target = 4;
    result = searchInsert(nums[0..], target);
    try std.testing.expect(result == 2);

    target = 7;
    result = searchInsert(nums[0..], target);
    try std.testing.expect(result == 4);
}
