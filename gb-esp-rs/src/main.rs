use log::info;
use gb_runner::*;

fn main() {
    esp_idf_svc::sys::link_patches();
    esp_idf_svc::log::EspLogger::initialize_default();

    let hi = run_print_hello();
    info!("{hi}")
}
