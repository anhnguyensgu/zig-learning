const std = @import("std");

fn binarySeach(arr: []i32, target: i32) !i32 {
    if (arr.len == 0) {
        return -1; 
    }
    var left: usize = 0;
    var right: usize = arr.len - 1;
    while (left <= right) {
        const mid = left + (right - left) / 2;
        if (arr[mid] == target) {
            return @intCast(mid);
        }

        if (target < arr[mid]) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }

    return -1;
}

test "binary search test - found" {
    var arr = [_]i32{ 1, 2, 3, 4, 5 };
    const target = 3;
    const result = try binarySeach(arr[0..], target);
    std.debug.print("Result: {d}\n", .{result});
    try std.testing.expect(result == 2);
}

test "binary search test - not found" {
    var arr = [_]i32{ 1, 2, 3, 4, 5 };
    const target = 6;
    const result = try binarySeach(arr[0..], target);
    std.debug.print("Result: {d}\n", .{result});
    try std.testing.expect(result == -1);
}

test "binary search test - first element" {
    var arr = [_]i32{ 1, 2, 3, 4, 5 };
    const target = 1;
    const result = try binarySeach(arr[0..], target);
    std.debug.print("Result: {d}\n", .{result});
    try std.testing.expect(result == 0);
}

test "binary search test - last element" {
    var arr = [_]i32{ 1, 2, 3, 4, 5 };
    const target = 5;
    const result = try binarySeach(arr[0..], target);
    std.debug.print("Result: {d}\n", .{result});
    try std.testing.expect(result == 4);
}

test "binary search test - empty array" {
    var arr: []i32 = &[_]i32{};
    const target = 1;
    const result = try binarySeach(arr[0..], target);
    std.debug.print("Result: {d}\n", .{result});
    try std.testing.expect(result == -1);
}
