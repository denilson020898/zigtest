const expect = @import("std").testing.expect;
const expectEqual = @import("std").testing.expectEqual;

test "test address of" {
    const x: i32 = 1234;
    const x_ptr = &x;

    const x_val = x_ptr.*;
    try expect(x == x_val);

    try expect(@TypeOf(x_ptr) == *const i32);

    var y: i32 = 5678;
    const y_ptr = &y;
    try expect(@TypeOf(y_ptr) == *i32);
    y_ptr.* += 1;
    try expect(y == 5679);
}

test "array access with pointer" {
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

    const individual_element = array[2];
    try expectEqual(@TypeOf(individual_element), u8);

    const slice = array[2..4];
    try expectEqual(@TypeOf(slice), *[2]u8);

    const elem_ptr = &array[2];
    try expectEqual(@TypeOf(elem_ptr), *u8);

    try expectEqual(array[2], 3);
    elem_ptr.* += 1;
    try expectEqual(array[2], 4);
}
