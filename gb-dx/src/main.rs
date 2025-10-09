use dioxus::prelude::*;
use gb_runner::*;

fn main() {
    dioxus::launch(App);
}

#[component]
fn App() -> Element {
    let hi = run_print_hello();
    rsx! {
        p { "{hi}" }
    }
}

