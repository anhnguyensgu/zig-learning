use std::io::{self, Read};

fn main() -> io::Result<()> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let mut iter = input.lines();
    let pattern = iter.next().unwrap_or("").to_string(); // "XX...X.X.X."
    let k: usize = iter.next().unwrap_or("0").parse().unwrap(); // 2

    let bytes = pattern.as_bytes();

    let mut i = 0;
    let mut j = 0;
    let mut ans = 0usize;
    let mut dots = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'.' {
            dots += 1;
        }
        while dots > k {
            if bytes[j] == b'.' {
                dots -= 1;
            }
            j += 1;
        }
        //edge case i == j when "."
        ans = ans.max(i - j + 1);
        i += 1;
    }

    println!("{ans}");
    Ok(())
}
