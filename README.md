# sfc.gen.live

`sfc.gen.live` is a translation of `phx.gen.live` to [Surface](https://surface-ui.org)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sfc_gen_live` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sfc_gen_live, "~> 0.1.4"}
  ]
end
```

## Usage

Use the same as you would `phx.gen.live`, for example:

```bash
mix sfc.gen.live Accounts User users name:string
```

## Caveats

- still creates `lib/app_web/live/live_helpers.ex`, but it is empty
- this is a pretty minimal translation to surface, which:
  - doesn't attempt to extract resource listing table to a component that can be re-used between resources
  - doesn't extract show / edit / delete buttons to components
  - ...however, you can copy the templates to `priv/templates/sfc.gen.live` and customize them further.
