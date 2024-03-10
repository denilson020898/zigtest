/// A sturcture for string a timestamp with nanosecond precision
/// multiline bro
const Timestamp = struct {
    /// The number of second since last epoch
    seconds: i64,
    /// something i don't understand as well
    nanos: u32,

    /// returns a `Timestamp` bla bba
    /// hahaahhah
    pub fn unixEpoch() Timestamp {
        return Timestamp{
            .seconds = 0,
            .nanos = 0,
        };
    }
};
