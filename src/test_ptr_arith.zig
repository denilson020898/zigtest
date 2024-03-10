const expect = @import("std").testing.expect;
const expectEqual = @import("std").testing.expectEqual;
const warn = @import("std").debug.warn;
const std = @import("std");

test "pointer arith with many items pointer " {
    const array = [_]i32{ 1, 2, 3, 4 };
    var ptr: [*]const i32 = &array;

    try expectEqual(ptr[0], 1);
    ptr += 1;
    try expectEqual(ptr[0], 2);

    try expect(ptr[1..2] == ptr + 1);
}
