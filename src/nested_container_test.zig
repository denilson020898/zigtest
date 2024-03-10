const std = @import("std");
const expect = std.testing.expect;

const imported_file = @import("testing_intro.zig");

test {
    std.testing.refAllDecls(@This());

    _ = S;
    _ = U;
    _ = @import("testing_intro.zig");
}

const S = struct {
    test "S demo test" {
        try expect(true);
        // try expect(false);
    }

    const SE = enum {
        V,
        test "This test won't run" {
            try expect(false);
        }
    };
};

const U = union {
    s: US,

    const US = struct {
        test "U.US demo test" {
            try expect(true);
        }
    };

    test "U demo test" {
        try expect(true);
    }
};
