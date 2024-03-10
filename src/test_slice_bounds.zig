const expect = @import("std").testing.expect;
const std = @import("std");

test "pointer slicing" {
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    var start: usize = 2;
    _ = &start; // suppress error, allow comptime?
    const slice = array[start..4];
    try expect(slice.len == 2);

    try expect(array[3] == 4);
    slice[1] += 1;
    try expect(array[3] == 6);

    std.debug.print("\narray is: {any}\n", .{array});
}
