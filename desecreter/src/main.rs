use std::str::FromStr;

use anyhow::Result;
use bcrypt::HashParts;
use csv::{ReaderBuilder, StringRecord, WriterBuilder};

const BYTES_PREFIX: &str = "\\\\x";

struct GolangBcrypt {}

impl GolangBcrypt {
    fn from_bytes(bytes: Vec<u8>) -> Result<HashParts> {
        let as_string = String::from_utf8(bytes.clone())?;
        Ok(HashParts::from_str(&as_string)?)
    }
}

fn sanitize(record: StringRecord, password: &str) -> Result<StringRecord> {
    if record.len() <= 1 {
        return Ok(record);
    }

    Ok(record
        .into_iter()
        .map(|field| match field.split_once(BYTES_PREFIX) {
            Some((_, hex_string)) => match hex::decode(hex_string) {
                Ok(bytes) => {
                    GolangBcrypt::from_bytes(bytes).expect("expected bcrypt");
                    password.to_owned()
                }
                Err(_) => field.to_owned(),
            },
            None => field.to_owned(),
        })
        .collect())
}

fn make_password() -> Result<String> {
    use rand::{distributions::Alphanumeric, Rng};

    let password: String = rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(32)
        .map(char::from)
        .collect();

    let mut field = BYTES_PREFIX.to_owned();
    field += hex::encode(
        bcrypt::hash_with_result(password, 10)?
            .to_string()
            .as_bytes(),
    )
    .as_str();

    Ok(field)
}

fn main() -> Result<()> {
    let mut reader = ReaderBuilder::new()
        .delimiter(b'\t')
        .flexible(true)
        .from_reader(std::io::stdin());

    let mut writer = WriterBuilder::new()
        .flexible(true)
        .quote_style(csv::QuoteStyle::Never)
        .from_writer(std::io::stdout());

    let password = make_password()?;

    for row in reader.records() {
        writer.write_record(&sanitize(row?, &password)?)?;
    }

    writer.flush()?;

    Ok(())
}
