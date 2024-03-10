const expect = @import("std").testing.expect;
const assert = @import("std").debug.assert;

const mat4x4 = [4][4]f32{
    [_]f32{ 1.0, 0.0, 0.0, 0.0 },
    [_]f32{ 0.0, 1.0, 0.0, 0.0 },
    [_]f32{ 0.0, 0.0, 1.0, 0.0 },
    [_]f32{ 0.0, 0.0, 0.0, 1.0 },
};

test "multidimensional" {
    try expect(mat4x4[1][1] == 1.0);

    for (mat4x4, 0..) |row, row_idx| {
        for (row, 0..) |cell, cell_idx| {
            if (row_idx == cell_idx) {
                try expect(cell == 1.0);
            }
        }
    }
}
