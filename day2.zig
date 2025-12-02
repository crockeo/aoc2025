const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("day2_input1.txt", .{});
    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);

    var segments = std.mem.splitScalar(u8, contents, ',');
    var part1_sum: usize = 0;
    var part2_sum: usize = 0;
    while (segments.next()) |segment| {
        const stripped_segment = std.mem.trim(u8, segment, " \r\n\t");
        const partition = std.mem.indexOfScalar(u8, stripped_segment, '-') orelse {
            @panic("Malformed data.");
        };

        const start_str = stripped_segment[0..partition];
        const start = try std.fmt.parseInt(usize, start_str, 10);

        const end_str = stripped_segment[partition + 1 ..];
        const end = try std.fmt.parseInt(usize, end_str, 10);

        for (start..end + 1) |num| {
            if (part1__is_invalid_id(num)) {
                part1_sum += num;
            }
            if (part2__is_invalid_id(num)) {
                part2_sum += num;
            }
        }
    }

    std.debug.print("{} {}\n", .{ part1_sum, part2_sum });
}

fn part1__is_invalid_id(id: usize) bool {
    const magnitude = std.math.log10(id);
    if (magnitude % 2 != 1) {
        return false;
    }
    const divisor = std.math.pow(usize, 10, (magnitude + 1) / 2);

    const lhs = id / divisor;
    const rhs = id % divisor;
    return lhs == rhs;
}

fn part2__is_invalid_id(id: usize) bool {
    const char_width = std.math.log10(id) + 1;
    if (id < 10) {
        return false;
    }
    for (1..(char_width / 2) + 1) |potential_width| {
        if (char_width % potential_width != 0) {
            continue;
        }
        const divisor = std.math.pow(usize, 10, @intCast(potential_width));
        const pattern = id % divisor;

        var search = id / divisor;
        while (search > 0 and search % divisor == pattern) {
            search /= divisor;
        }
        if (search == 0) {
            return true;
        }
    }
    return false;
}

test "part2__is_invalid_id -- valid" {
    for ([_]usize{ 1, 1234, 57102 }) |id| {
        std.testing.expectEqual(false, part2__is_invalid_id(id)) catch |e| {
            std.debug.print("{}\n", .{id});
            return e;
        };
    }
}

test "part2__is_invalid_id -- invalid" {
    for ([_]usize{ 11, 111, 1111, 1212, 123123, 12341234, 121212, 123123123 }) |id| {
        std.testing.expectEqual(true, part2__is_invalid_id(id)) catch |e| {
            std.debug.print("{}\n", .{id});
            return e;
        };
    }
}
