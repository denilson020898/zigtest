const std = @import("std");
const math = std.math;
const testing = std.testing;

test "fn reflection" {
    try testing.expect(@typeInfo(@TypeOf(testing.expect)).Fn.params[0].type.? == bool);
    try testing.expect(@typeInfo(@TypeOf(testing.tmpDir)).Fn.return_type.? == testing.TmpDir);
    try testing.expect(@typeInfo(@TypeOf(math.Log2Int)).Fn.is_generic);
}

const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error{
    OutOfMemory,
};

test "coerce subset to superset error set type" {
    const err = fooErrorSet(AllocationError.OutOfMemory);
    try std.testing.expect(err == FileOpenError.OutOfMemory);
}

fn fooErrorSet(err: AllocationError) FileOpenError {
    return err;
}

fn fooErrorSetInverted(err: FileOpenError) AllocationError {
    return err;
}

test "coerce superset to subset is not allowed in error set type" {
    // will error
    // fooErrorSetInverted(FileOpenError.OutOfMemory) catch {};

    const err = error.FileNotFound;
    const err2 = (error{FileNotFound}).FileNotFound;
    try testing.expectEqual(err, err2);
}
