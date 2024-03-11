const std = @import("std");
const eq = std.testing.expectEqual;
const ee = std.testing.expectError;
const expect = std.testing.expect;
const native_endian = @import("builtin").target.cpu.arch.endian();
const mem = std.mem;
const builtin = @import("builtin");

const Point = struct {
    x: f32,
    y: f32,
};

const Point2 = packed struct {
    x: f32,
    y: f32,
};

const p = Point{
    .x = 0.12,
    .y = 0.34,
};

const p2 = Point{
    .x = 0.12,
    .y = undefined,
};

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }
};

test "dot product" {
    const v1 = Vec3.init(1.0, 0.0, 0.0);
    const v2 = Vec3.init(0.0, 1.0, 0.0);

    try eq(v1.dot(v2), 0.0);
    try eq(Vec3.dot(v1, v2), 0.0);
    try eq(Vec3.dot(v2, v1), 0.0);
}

const Empty = struct {
    pub const PI = 3.14;
};

test "struct namespaced vars" {
    try eq(Empty.PI, 3.14);
    try eq(@sizeOf(Empty), 0);
    const does_nothing = Empty{};
    _ = does_nothing;
}

// from Point.x get Point to modith Point.y
fn setYBasedOnX(x: *f32, y: f32) void {
    const point = @fieldParentPtr(Point, "x", x);
    point.y = y;
}

test "field parent ptr" {
    var point = Point{
        .x = 0.1234,
        .y = 0.5678,
    };
    setYBasedOnX(&point.x, 0.9);
    try eq(point.y, 0.9);
}

fn LinkedList(comptime T: type) type {
    return struct {
        pub const Node = struct { prev: ?*Node, next: ?*Node, data: T };

        first: ?*Node,
        last: ?*Node,
        len: usize,
    };
}

test "linked list" {
    try eq(LinkedList(i32), LinkedList(i32));

    const list = LinkedList(i32){
        .first = null,
        .last = null,
        .len = 0,
    };

    try eq(list.len, 0);

    const ListOfInts = LinkedList(i32);
    try eq(ListOfInts, LinkedList(i32));

    var node = ListOfInts.Node{
        .prev = null,
        .next = null,
        .data = 1234,
    };
    const list2 = LinkedList(i32){
        .first = &node,
        .last = &node,
        .len = 1,
    };

    try eq(node.prev, null);
    try eq(list2.first.?.data, 1234);
}

const Foo = struct {
    a: i32 = 1234,
    b: i32,
};

test "default value " {
    const x = Foo{
        .b = 5,
    };
    if (x.a + x.b != 1239) {
        @compileError("it's even catched at comptime");
    }
}

// 4 bytes is 32 bit

const Full = packed struct {
    number: u16,
};

const Divided = packed struct {
    half1: u8,
    quarter3: u4,
    quarter4: u4,
};

fn doTheTest() !void {
    try eq(@sizeOf(Full), 2); // 2 bytes * 8 = 16 bit
    try eq(@sizeOf(Divided), 2);

    const full = Full{ .number = 0x1234 };
    const divided: Divided = @bitCast(full);

    try eq(divided.half1, 0x34);
    try eq(divided.quarter3, 0x2);
    try eq(divided.quarter4, 0x1);

    const ordered: [2]u8 = @bitCast(full);
    switch (native_endian) {
        .big => {
            try eq(ordered[0], 0x12);
            try eq(ordered[1], 0x34);
        },
        .little => {
            try eq(ordered[0], 0x34);
            try eq(ordered[1], 0x12);
        },
    }
}

test "@bitCast packet struct" {
    try doTheTest();
    try comptime doTheTest();
}

const BitField = packed struct {
    a: u3,
    b: u3,
    c: u2,
};

var foo = BitField{
    .a = 1,
    .b = 2,
    .c = 3,
};

test "non aligned ptr field" {
    const ptr = &foo.b;
    const ptr_c = &foo.c;
    try eq(ptr.*, 2);
    try eq(ptr_c.*, 3);
}

fn bar(x: *const u3) u3 {
    return x.*;
}

// test "ptr to non aligned field" {
//     try eq(bar(&foo.b), 2);
// }

test "ptr of sub byte aligned" {
    try eq(@intFromPtr(&foo.a), @intFromPtr(&foo.b));
    try eq(@intFromPtr(&foo.a), @intFromPtr(&foo.c));
}

test "ptr of sub byte aligned observe" {
    comptime {
        try eq(@bitOffsetOf(BitField, "a"), 0);
        try eq(@bitOffsetOf(BitField, "b"), 3);
        try eq(@bitOffsetOf(BitField, "c"), 6);

        try eq(@offsetOf(BitField, "a"), 0);
        try eq(@offsetOf(BitField, "b"), 0);
        try eq(@offsetOf(BitField, "c"), 0);
    }
}

const S = packed struct {
    a: u32, // 32 bit / 8 = 4 byte
    b: u32,
};

test "overaligned point to packed struct" {
    var foo2: S align(4) = .{ .a = 1, .b = 2 };
    const ptr: *align(4) S = &foo2;
    const ptr_to_b: *u32 = &ptr.b;
    try eq(ptr_to_b.*, 2);
}

test "aligned structs" {
    const S2 = struct {
        a: u32 align(2),
        b: u32 align(64),
    };

    var foo2 = S2{ .a = 1, .b = 2 };

    try eq(64, @alignOf(S2));
    try eq(*align(2) u32, @TypeOf(&foo2.a));
    try eq(*align(64) u32, @TypeOf(&foo2.b));
}

fn List(comptime T: type) type {
    return struct {
        x: T,
    };
}

test "struct naming" {
    const Foo2 = struct {};
    _ = Foo2;
    // std.debug.print("\nvariable: {s}\n", .{@typeName(Foo2)});
    // std.debug.print("anon: {s}\n", .{@typeName(struct {})});
    // std.debug.print("fn: {s}\n\n", .{@typeName(List(i32))});
}

const Point3 = struct { x: i32, y: i32 };
test "anon struct literal" {
    const pt: Point3 = .{
        .x = 13,
        .y = 67,
    };

    try eq(pt.x, 13);
    try eq(pt.y, 67);
}

test "fully anon struct" {
    try check(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}

fn check(args: anytype) !void {
    try eq(args.int, 1234);
    try eq(args.float, 12.34);
    try eq(args.b, true);
    try expect(args.s[0] == 'h');
    try expect(args.s[1] == 'i');
}

test "tuple" {
    const values = .{ @as(u32, 1234), @as(f64, 12.34), true, "hi" } ++ .{false} ** 2;

    try eq(values[0], 1234);
    try eq(values[4], false);
    inline for (values, 0..) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try eq(values.len, 6);
    // try eq(values[3], 'h');
    try eq(values.@"3"[0], 'h');
}

const Type = enum {
    ok,
    not_ok,
};

const c = Type.ok;

const Value = enum(u32) {
    zero,
    one,
    two,
};

const Value2 = enum(u32) {
    hundred = 100,
    thousand = 1000,
    million = 1000000,
};

const Value3 = enum(u32) {
    a,
    b = 8,
    c,
    d = 4,
    e,
};

test "enum order value" {
    try eq(@intFromEnum(Value.zero), 0);
    try eq(@intFromEnum(Value.one), 1);
    try eq(@intFromEnum(Value.two), 2);

    try eq(@intFromEnum(Value2.hundred), 100);
    try eq(@intFromEnum(Value2.thousand), 1000);
    try eq(@intFromEnum(Value2.million), 1000000);

    try eq(@intFromEnum(Value3.a), 0);
    try eq(@intFromEnum(Value3.b), 8);
    try eq(@intFromEnum(Value3.c), 9);
    try eq(@intFromEnum(Value3.d), 4);
    try eq(@intFromEnum(Value3.e), 5);
}

const Suit = enum {
    clubs,
    spades,
    diamons,
    hearts,

    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    const spade = Suit.spades;
    try expect(!spade.isClubs());

    const club = Suit.clubs;
    try expect(club.isClubs());
}

const FooEnum = enum {
    string,
    number,
    none,
};

test "enum switch" {
    const p_local = FooEnum.number;

    const what_is_it = switch (p_local) {
        FooEnum.string => "this is a string",
        FooEnum.number => "this is a number",
        FooEnum.none => "this is a none",
    };

    try expect(mem.eql(u8, what_is_it, "this is a number"));
}

const Small = enum {
    one,
    two,
    three,
    four,
};

test "std.meta.Tag" {
    try eq(@typeInfo(Small).Enum.tag_type, u2);
}

test "@typeInfo" {
    try eq(@typeInfo(Small).Enum.fields.len, 4);
    try expect(mem.eql(u8, @typeInfo(Small).Enum.fields[1].name, "two"));
}

test "@tagName" {
    try expect(mem.eql(u8, @tagName(Small.three), "three"));
}

const Color = enum {
    auto,
    off,
    on,
};

test "enum literals" {
    const color1: Color = .auto;
    const color2 = Color.auto;
    try eq(color1, color2);
}

test "switch enum literals" {
    const color = Color.on;

    const result = switch (color) {
        .auto => false,
        .on => true,
        .off => false,
    };

    try expect(result);
}

const Number = enum(u8) {
    one,
    two,
    three,
    _,
};

test "switch on non exhaustive enum" {
    const number = Number.one;
    const result = switch (number) {
        .one => true,
        .two, .three => false,
        _ => false,
    };

    try expect(result);

    const is_one = switch (number) {
        .one => true,
        else => false,
    };

    try expect(is_one);
}

const Payload = union {
    int: i64,
    float: f64,
    boolean: bool,
};

test "simple union" {
    var payload = Payload{ .int = 1234 };
    // payload.float = 12.34;
    try expect(payload.int == 1234);

    payload = Payload{ .float = 12.34 };
    try expect(payload.float == 12.34);
}

const ComplexTypeTag = enum {
    ok,
    not_ok,
};

const ComplexType = union(ComplexTypeTag) {
    ok: u8,
    not_ok: void,
};

test "switch on tagged union" {
    const c2 = ComplexType{ .ok = 42 };
    try expect(@as(ComplexTypeTag, c2) == ComplexTypeTag.ok);

    switch (c2) {
        ComplexTypeTag.ok => |value| try expect(value == 42),
        ComplexTypeTag.not_ok => unreachable,
    }
}

test "get tag type" {
    try expect(std.meta.Tag(ComplexType) == ComplexTypeTag);
}

test "modify tagged union in switch" {
    var c3 = ComplexType{ .ok = 42 };
    switch (c3) {
        ComplexTypeTag.ok => |*value| value.* += 1,
        ComplexTypeTag.not_ok => unreachable,
    }
    try expect(c3.ok == 43);
}

const Variant = union(enum) {
    int: i32,
    boolean: bool,

    none,

    fn truthy(self: Variant) bool {
        return switch (self) {
            Variant.int => |x_int| x_int != 0,
            Variant.boolean => |x_bool| x_bool,
            Variant.none => false,
        };
    }
};

test "union method" {
    var v1 = Variant{ .int = 1 };
    var v2 = Variant{ .boolean = false };
    try expect(v1.truthy());
    try expect(!v2.truthy());
}

const Small2 = union(enum) {
    a: i32,
    b: bool,
    c: u8,
};

test "@tagName2" {
    try expect(std.mem.eql(u8, @tagName(Small2.a), "a"));
}

const Number2 = union {
    int: i32,
    float: f64,
};

fn makeNumber() Number2 {
    return .{ .float = 12.34 };
}

test "anon union literal syntax" {
    const i: Number2 = .{ .int = 42 };
    const f = makeNumber();
    try eq(i.int, 42);
    try eq(f.float, 12.34);
}

const Derp = opaque {};
const Wat = opaque {};

extern fn bar3(d: *Derp) void;
fn foo3(w: *Wat) callconv(.C) void {
    bar3(w);
}

test "call foo" {
    // foo3(undefined);
}

test "accessing vars block" {
    {
        var x: i32 = 1;
        _ = &x;
        x += 1;
    }
    // x += 1;
}

test "labeled break from labeled block" {
    var y: i32 = 123;
    const x = blk: {
        y += 1;
        break :blk y;
    };
    try eq(x, 124);
    try eq(y, 124);
}

const pi = 3.14;
test "test var shadow block" {
    // {
    //     var p: i32 = 1233;
    // }
}

test "test var separated block" {
    {
        const pi2 = 3.14;
        _ = &pi2;
    }

    {
        const pi2 = true;
        _ = &pi2;
    }
}

test "empty block" {
    const a = {};
    const b = void{};
    try eq(@TypeOf(a), void);
    try eq(@TypeOf(b), void);
    try eq(a, b);
}

test "switch simple" {
    const a: u64 = 10;
    const zz: u64 = 103;

    const b = switch (a) {
        1, 2, 3 => 0,
        5...100 => 1,
        101 => blk: {
            const c2: u64 = 5;
            break :blk c2 * 2 + 1;
        },

        zz => zz,
        blk: {
            const d: u32 = 5;
            const e: u32 = 100;
            break :blk d + e;
        } => 107,
        else => 9,
    };

    try eq(b, 1);
}

const os_msg = switch (builtin.target.os.tag) {
    .linux => "we found a linux user",
    else => "bingbong",
};

test "switch inside function" {
    switch (builtin.target.os.tag) {
        .fuchsia => {
            @compileError("bruh, not supported lah");
        },
        else => {},
    }
}

test "switch on tagged union2" {
    const Point4 = struct {
        x: u8,
        y: u8,
    };

    const Item4 = union(enum) {
        a: u32,
        c: Point4,
        d,
        e: u32,
    };

    var a = Item4{ .c = Point4{ .x = 1, .y = 2 } };
    const b = switch (a) {
        Item4.a, Item4.e => |item| item,
        Item4.c => |*item| blk: {
            item.*.x += 1;
            break :blk 6;
        },
        Item4.d => 8,
    };

    try eq(b, 6);

    try eq(a.c.x, 2);
}

const Color2 = enum { auto, off, on };

test "exhaustive switching" {
    const color = Color2.off;
    const result = switch (color) {
        Color2.auto => true,
        Color2.on => true,
        Color2.off => false,
    };

    try eq(result, false);
}

fn isFieldOptional(comptime T: type, field_index: usize) !bool {
    const fields = @typeInfo(T).Struct.fields;
    return switch (field_index) {
        inline 0, 1 => |idx| @typeInfo(fields[idx].type) == .Optional,
        else => return error.IndexOutOfBounds,
    };
}

const Struct1 = struct { a: u32, b: ?u32 };

test "using @typeInfo with rt vals" {
    var index: usize = 0;
    try expect(!try isFieldOptional(Struct1, index));
    index += 1;
    try expect(try isFieldOptional(Struct1, index));
    index += 1;
    try ee(error.IndexOutOfBounds, isFieldOptional(Struct1, index));
}

test "while basic" {
    var i: usize = 0;
    while (i < 10) {
        i += 1;
    }
    try eq(i, 10);
}

test "while break basic" {
    var i: usize = 0;
    while (true) {
        if (i == 10) {
            break;
        }
        i += 1;
    }
    try eq(i, 10);
}

test "while continue basic" {
    var i: usize = 0;
    while (true) {
        i += 1;
        if (i < 10) {
            continue;
        }
        break;
    }
    try eq(i, 10);
}

test "while loop continue expr" {
    var i: usize = 0;
    while (i < 10) : (i += 1) {}
    try eq(i, 10);
}

test "while loop continue expr, complex" {
    var i: usize = 1;
    var j: usize = 1;

    while (i * j < 2000) : ({
        i *= 2;
        j *= 3;
    }) {
        const my_ij = i * j;
        try expect(my_ij < 2000);
    }
}

test "while else" {
    try expect(rangeHasNumber(0, 10, 5));
    try expect(!rangeHasNumber(0, 10, 15));
}

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "nested break" {
    outer: while (true) {
        while (true) {
            break :outer;
        }
    }
}

test "nested continue" {
    var i: usize = 0;
    outer: while (i < 10) : (i += 1) {
        while (true) {
            continue :outer;
        }
    }
}

var numbers_left: u32 = undefined;
fn eventuallyNullSequence() ?u32 {
    return if (numbers_left == 0) null else blk: {
        numbers_left -= 1;
        break :blk numbers_left;
    };
}

test "while null capture" {
    var sum1: u32 = 0;
    numbers_left = 3;

    while (eventuallyNullSequence()) |value| {
        sum1 += value;
    }

    try eq(sum1, 3);

    var sum2: u32 = 0;
    numbers_left = 3;

    while (eventuallyNullSequence()) |value| {
        sum2 += value;
    } else {
        try eq(sum2, 3);
    }

    var i: u32 = 0;
    var sum3: u32 = 0;
    numbers_left = 3;

    while (eventuallyNullSequence()) |value| : (i += 1) {
        sum3 += value;
    }
    try expect(i == 3);
}

var numbers_left2: u32 = undefined;
fn eventuallyErrorSequence() anyerror!u32 {
    return if (numbers_left2 == 0) error.ReachedZero else blk: {
        numbers_left2 -= 1;
        break :blk numbers_left2;
    };
}

test "while error union capture" {
    var sum1: u32 = 0;
    numbers_left2 = 3;
    while (eventuallyErrorSequence()) |value| {
        sum1 += value;
    } else |err| {
        try eq(err, error.ReachedZero);
    }
}

test "inline while loop" {
    comptime var i = 0;
    var sum: usize = 0;
    inline while (i < 3) : (i += 1) {
        const T = switch (i) {
            0 => f32,
            1 => i8,
            2 => bool,
            else => unreachable,
        };
        sum += typeNameLength(T);
    }
    try expect(sum == 9);
}

fn typeNameLength(comptime T: type) usize {
    return @typeName(T).len;
}
