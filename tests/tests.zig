const std = @import("std");
const protobuf = @import("protobuf");
usingnamespace protobuf;
usingnamespace std;
const eql = mem.eql;

const Demo1 = struct {
    a : ?u32,

    pub const _desc_table = [_]FieldDescriptor{
        fd(1, "a", .{.Varint = .Simple}),
    };

    pub fn encode(self: Demo1, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn decode(input: []const u8, allocator: *mem.Allocator) !Demo1 {
        return pb_decode(Demo1, input, allocator);
    }

    pub fn deinit(self: Demo1) void {
        pb_deinit(self);
    }
};

test "basic encoding" {
    var demo = Demo1{.a = 150};
    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);
    // 0x08 , 0x96, 0x01
    testing.expectEqualSlices(u8, &[_]u8{0x08, 0x96, 0x01}, obtained);

    demo.a = 0;
    const obtained2 = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained2);
    // 0x08 , 0x96, 0x01
    testing.expectEqualSlices(u8, &[_]u8{0x08, 0x00}, obtained2);
}

test "basic decoding" {
    const input = [_]u8{0x08, 0x96, 0x01};
    const obtained = try Demo1.decode(&input, testing.allocator);

    testing.expectEqual(Demo1{.a = 150}, obtained);

    const input2 = [_]u8{0x08, 0x00};
    const obtained2 = try Demo1.decode(&input2, testing.allocator);
    testing.expectEqual(Demo1{.a = 0}, obtained2);

}

const Demo2 = struct {
    a : ?u32,
    b : ?u32,

    pub const _desc_table = [_]FieldDescriptor{
        fd(1, "a", .{.Varint = .ZigZagOptimized}),
        fd(2, "b", .{.Varint = .ZigZagOptimized}),
    };

    pub fn encode(self: Demo2, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: Demo2) void {
        pb_deinit(self);
    }
};

test "basic encoding with optionals" {
    const demo = Demo2{.a = 150, .b = null};
    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);
    // 0x08 , 0x96, 0x01
    testing.expectEqualSlices(u8, &[_]u8{0x08, 0x96, 0x01}, obtained);

    const demo2 = Demo2{.a = 150, .b = 150};
    const obtained2 = try demo2.encode(testing.allocator);
    defer testing.allocator.free(obtained2);
    // 0x08 , 0x96, 0x01
    testing.expectEqualSlices(u8, &[_]u8{0x08, 0x96, 0x01, 0x10, 0x96, 0x01}, obtained2);
}

const WithNegativeIntegers = struct {
    a: ?i32, // int32
    b: ?i32, // sint32

    pub const _desc_table = [_]FieldDescriptor{
        fd(1, "a", .{.Varint = .ZigZagOptimized}),
        fd(2, "b", .{.Varint = .Simple}),
    };

    pub fn encode(self: WithNegativeIntegers, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: WithNegativeIntegers) void {
        pb_deinit(self);
    }
};

test "basic encoding with negative numbers" {
    var demo = WithNegativeIntegers{.a = -2, .b = -1};
    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);
    // 0x08
    testing.expectEqualSlices(u8, &[_]u8{0x08, 0x03, 0x10, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F}, obtained);
}

const DemoWithAllVarint = struct {
    
    const DemoEnum = enum(i32) {
        SomeValue,
        SomeOther,
        AndAnother
    };
    
    sint32: ?i32,  //sint32
    sint64: ?i64,  //sint64
    uint32: ?u32,  //uint32
    uint64: ?u64,  //uint64
    a_bool: ?bool, //bool
    a_enum: ?DemoEnum, // enum
    pos_int32: ?i32,
    pos_int64: ?i64,
    neg_int32: ?i32,
    neg_int64: ?i64,


    pub const _desc_table = [_]FieldDescriptor{
        fd( 1, "sint32"     , .{.Varint = .ZigZagOptimized}),
        fd( 2, "sint64"     , .{.Varint = .ZigZagOptimized}),
        fd( 3, "uint32"     , .{.Varint = .Simple}),
        fd( 4, "uint64"     , .{.Varint = .Simple}),
        fd( 5, "a_bool"     , .{.Varint = .Simple}),
        fd( 6, "a_enum"     , .{.Varint = .ZigZagOptimized}),
        fd( 7, "pos_int32"  , .{.Varint = .Simple}),
        fd( 8, "pos_int64"  , .{.Varint = .Simple}),
        fd( 9, "neg_int32"  , .{.Varint = .Simple}),
        fd(10, "neg_int64"  , .{.Varint = .Simple}),
    };

    pub fn encode(self: DemoWithAllVarint, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn decode(input: []const u8, allocator: *mem.Allocator) !DemoWithAllVarint {
        return pb_decode(DemoWithAllVarint, input, allocator);
    }

    pub fn deinit(self: DemoWithAllVarint) void {
        pb_deinit(self);
    }
};

test "DemoWithAllVarint" {
    var demo = DemoWithAllVarint{
        .sint32 = -1,
        .sint64 = -1,
        .uint32 = 150,
        .uint64 = 150,
        .a_bool = true,
        .a_enum = DemoWithAllVarint.DemoEnum.AndAnother,
        .pos_int32 = 1,
        .pos_int64 = 2,
        .neg_int32 = -1,
        .neg_int64 = -2
    };
    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);
    // 0x08 , 0x96, 0x01
    testing.expectEqualSlices(u8, &[_]u8{
            0x08, 0x01,
            0x10, 0x01,
            0x18, 0x96, 0x01,
            0x20, 0x96, 0x01,
            0x28, 0x01,
            0x30, 0x02,
            0x38, 0x01,
            0x40, 0x02,
            0x48, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F,
            0x50, 0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01
        },obtained);
}

test "decodevarint" {
    var expected = DemoWithAllVarint{
        .sint32 = -1,
        .sint64 = -1,
        .uint32 = 150,
        .uint64 = 150,
        .a_bool = true,
        .a_enum = DemoWithAllVarint.DemoEnum.AndAnother,
        .pos_int32 = 1,
        .pos_int64 = 2,
        .neg_int32 = -1,
        .neg_int64 = -2
    };

    const encoded = [_]u8{
            0x08, 0x01,
            0x10, 0x01,
            0x18, 0x96, 0x01,
            0x20, 0x96, 0x01,
            0x28, 0x01,
            0x30, 0x02,
            0x38, 0x01,
            0x40, 0x02,
            0x48, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F,
            0x50, 0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01
    };

    const decoded = try DemoWithAllVarint.decode(&encoded, testing.allocator);
    testing.expectEqual(expected, decoded);
}


const FixedSizes = struct {
    sfixed64 : ?i64,
    sfixed32 : ?i32,
    fixed32  : ?u32,
    fixed64  : ?u64,
    double   : ?f64,
    float    : ?f32,

    pub const _desc_table = [_]FieldDescriptor{
        fd( 1, "sfixed64"   , .FixedInt),
        fd( 2, "sfixed32"   , .FixedInt),
        fd( 3, "fixed32"    , .FixedInt),
        fd( 4, "fixed64"    , .FixedInt),
        fd( 5, "double"     , .FixedInt),
        fd( 6, "float"      , .FixedInt),
    };

    pub fn encode(self: FixedSizes, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: FixedSizes) void {
        pb_deinit(self);
    }
};

test "FixedSizes" {
    var demo = FixedSizes{
        .sfixed64 = -1,
        .sfixed32 = -2,
        .fixed32 = 1,
        .fixed64 = 2,
        .double = 5.0, // 0x4014000000000000 
        .float = 5.0 // 0x40a00000
    };

    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);

    testing.expectEqualSlices(u8, &[_]u8{
        0x08 + 1 , 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0x10 + 5 , 0xFE, 0xFF, 0xFF, 0xFF,
        0x18 + 5 , 0x01, 0x00, 0x00, 0x00,
        0x20 + 1 , 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x28 + 1 , 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x40,
        0x30 + 5 , 0x00, 0x00, 0xa0, 0x40
    }, obtained);
}

const WithSubmessages = struct {
    sub_demo1 : ?Demo1,
    sub_demo2 : ?Demo2,

    pub const _desc_table = [_]FieldDescriptor{
        fd( 1, "sub_demo1"   , .SubMessage),
        fd( 2, "sub_demo2"   , .SubMessage),
    };

    pub fn encode(self: WithSubmessages, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: WithSubmessages) void {
        pb_deinit(self);
    }
};

test "WithSubmessages" {
    var demo = WithSubmessages{
        .sub_demo1 = .{.a = 1},
        .sub_demo2 = .{.a = 2, .b = 3}
    };

    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);

    testing.expectEqualSlices(u8, &[_]u8{
        0x08 + 2, 0x02,
            0x08, 0x01,
        0x10 + 2, 0x04,
            0x08, 0x02,
            0x10, 0x03
    }, obtained);
}

const WithBytes = struct {
    list_of_data: ArrayList(u8),

    pub const _desc_table = [_]FieldDescriptor{
        fd( 1, "list_of_data", .{.List = .FixedInt}),
    };

    pub fn encode(self: WithBytes, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: WithBytes) void {
        pb_deinit(self);
    }

    pub fn init(allocator: *mem.Allocator) WithBytes {
        return pb_init(WithBytes, allocator);
    }
};

test "bytes"  {
    var demo = WithBytes.init(testing.allocator);
    try demo.list_of_data.append(0x08);
    try demo.list_of_data.append(0x01);
    defer demo.deinit();

    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);

    testing.expectEqualSlices(u8, &[_]u8{
        0x08 + 2, 0x02,
            0x08, 0x01,
    }, obtained);
}

const FixedSizesList = struct {
    fixed32List  : ArrayList(u32),

    pub const _desc_table = [_]FieldDescriptor{
        fd( 1, "fixed32List"   , .{.List = .FixedInt}),
    };

    pub fn encode(self: FixedSizesList, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: FixedSizesList) void {
        pb_deinit(self);
    }

    pub fn init(allocator: *mem.Allocator) FixedSizesList {
        return pb_init(FixedSizesList, allocator);
    }
};

fn log_slice(slice : []const u8) void {
    std.log.warn("{}", .{std.fmt.fmtSliceHexUpper(slice)});
}

test "FixedSizesList" {
    var demo = FixedSizesList.init(testing.allocator);
    try demo.fixed32List.append(0x01);
    try demo.fixed32List.append(0x02);
    try demo.fixed32List.append(0x03);
    try demo.fixed32List.append(0x04);
    defer demo.deinit();

    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);

    testing.expectEqualSlices(u8, &[_]u8{
        0x08 + 2, 0x10,
            0x01, 0x00, 0x00, 0x00,
            0x02, 0x00, 0x00, 0x00,
            0x03, 0x00, 0x00, 0x00,
            0x04, 0x00, 0x00, 0x00,
    }, obtained);
}

const VarintList = struct {
    varuint32List  : ArrayList(u32),

    pub const _desc_table = [_]FieldDescriptor{
        fd( 1, "varuint32List"   , .{.List = .{.Varint = .Simple}}),
    };

    pub fn encode(self: VarintList, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: VarintList) void {
        pb_deinit(self);
    }

    pub fn init(allocator: *mem.Allocator) VarintList {
        return pb_init(VarintList, allocator);
    }
};

test "VarintList" {
    var demo = VarintList.init(testing.allocator);
    try demo.varuint32List.append(0x01);
    try demo.varuint32List.append(0x02);
    try demo.varuint32List.append(0x03);
    try demo.varuint32List.append(0x04);
    defer demo.deinit();

    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);

    testing.expectEqualSlices(u8, &[_]u8{
        0x08 + 2, 0x04,
            0x01,
            0x02,
            0x03,
            0x04,
    }, obtained);
}

const SubMessageList = struct {
    subMessageList  : ArrayList(Demo1),

    pub const _desc_table = [_]FieldDescriptor{
        fd( 1, "subMessageList"   , .{.List = .SubMessage}),
    };

    pub fn encode(self: SubMessageList, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: SubMessageList) void {
        pb_deinit(self);
    }

    pub fn init(allocator: *mem.Allocator) SubMessageList {
        return pb_init(SubMessageList, allocator);
    }
};

// .{.a = 1}

test "SubMessageList" {
    var demo = SubMessageList.init(testing.allocator);
    try demo.subMessageList.append(.{.a = 1});
    try demo.subMessageList.append(.{.a = 2});
    try demo.subMessageList.append(.{.a = 3});
    try demo.subMessageList.append(.{.a = 4});
    defer demo.deinit();

    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);

    testing.expectEqualSlices(u8, &[_]u8{
        0x08 + 2, 
            0x0C,
                0x02, 
                    0x08, 0x01,
                0x02, 
                    0x08, 0x02,
                0x02, 
                    0x08, 0x03,
                0x02, 
                    0x08, 0x04,
    }, obtained);
}

const EmptyLists = struct {
    varuint32List  : ArrayList(u32),
    varuint32Empty : ArrayList(u32),


    pub const _desc_table = [_]FieldDescriptor{
        fd( 1, "varuint32List"   , .{.List = .{.Varint = .Simple}}),
        fd( 2, "varuint32Empty"  , .{.List = .{.Varint = .Simple}}),
    };

    pub fn encode(self: EmptyLists, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: EmptyLists) void {
        pb_deinit(self);
    }

    pub fn init(allocator: *mem.Allocator) EmptyLists {
        return pb_init(EmptyLists, allocator);
    }
};

test "EmptyLists" {
    var demo = EmptyLists.init(testing.allocator);
    try demo.varuint32List.append(0x01);
    try demo.varuint32List.append(0x02);
    try demo.varuint32List.append(0x03);
    try demo.varuint32List.append(0x04);
    defer demo.deinit();

    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);

    testing.expectEqualSlices(u8, &[_]u8{
        0x08 + 2, 0x04,
            0x01,
            0x02,
            0x03,
            0x04,
    }, obtained);
}

const EmptyMessage = struct {
    
    pub const _desc_table = [_]FieldDescriptor{};

    pub fn encode(self: EmptyMessage, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn deinit(self: EmptyMessage) void {
        pb_deinit(self);
    }

    pub fn init(allocator: *mem.Allocator) EmptyMessage {
        return pb_init(EmptyMessage, allocator);
    }
};

test "EmptyMessage" {
    var demo = EmptyMessage.init(testing.allocator);
    defer demo.deinit();

    const obtained = try demo.encode(testing.allocator);
    defer testing.allocator.free(obtained);

    testing.expectEqualSlices(u8, &[_]u8{}, obtained);
}

const DefaultValuesInit = struct {
    a : ?u32 = 5,
    b : ?u32,
    c : ?u32 = 3,
    d : ?u32,

    pub const _desc_table = [_]FieldDescriptor{
        fd(1, "a", .{.Varint = .ZigZagOptimized}),
        fd(2, "b", .{.Varint = .ZigZagOptimized}),
        fd(3, "c", .{.Varint = .ZigZagOptimized}),
        fd(4, "d", .{.Varint = .ZigZagOptimized}),
    };

    pub fn encode(self: DefaultValuesInit, allocator: *mem.Allocator) ![]u8 {
        return pb_encode(self, allocator);
    }

    pub fn init(allocator: *mem.Allocator) DefaultValuesInit {
        return pb_init(DefaultValuesInit, allocator);
    }

    pub fn deinit(self: DefaultValuesInit) void {
        pb_deinit(self);
    }
};

test "DefaultValuesInit" {
    var demo = DefaultValuesInit.init(testing.allocator);
    testing.expectEqual(@as(u32, 5), demo.a.?);
    testing.expectEqual(@as(u32, 3), demo.c.?);
    testing.expect(if(demo.b) |val| false else true);
    testing.expect(if(demo.d) |val| false else true);
}