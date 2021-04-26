# sfc.gen.live

`sfc.gen.live` is a translation of `phx.gen.live` to [Surface](https://surface-ui.org).
It also contains a generator for generating standalone Surface Components

## Installation

I haven't put this on Hex yet, so the package can be installed
by adding `sfc_gen_live` as a git dependency to your list of
dependencies in `mix.exs`:

## Upstream

This may be merged with [Surface](https://github.com/surface-ui/surface) at some pont; there is discussion on [this issue](https://github.com/surface-ui/surface/issues/333).

### With Phoenix v1.5.8

```elixir
def deps do
  [
    {:sfc_gen_live, git: "https://github.com/lastobelus/sfc_gen_live.git", branch: "phoenix_1.5.8"}
  ]
end
```

### With Phoenix from master branch

```elixir
def deps do
  [
    {:sfc_gen_live, git: "https://github.com/lastobelus/sfc_gen_live.git"}
  ]
end
```

## Usage

### `sfc.gen.init`

Sets up a project (that was generated with `mix phx.new --live`) to use Surface.
Optionally adds a demo card component if the option `--demo` is passed.
By default this will be a two-file component (`card.ex` and `card.sface`).
If you pass `--no-template` it will be generated as a single file component
with the template in a render function and `~H` sigil.

### `sfc.gen.live`

Use the same as you would `phx.gen.live`, for example:

```bash
mix sfc.gen.live Accounts User users name:string
```

#### Caveats

- still creates `lib/app_web/live/live_helpers.ex`, but it is empty
- this is a pretty minimal translation to surface, which:
  - doesn't attempt to extract resource listing table to a component that can be re-used between resources
  - doesn't extract show / edit / delete buttons to components
  - ...however, you can copy the templates to `priv/templates/sfc.gen.live` and customize them further.

### `sfc.gen.component`

mix sfc.gen.component expects a component module name, and an optional `namespace`
option that is a valid module name.
The component name and/or namespace can also be supplied in 'underscore' form.
For example:

```bash
mix sfc.gen.component Button
mix sfc.gen.component table/head
mix sfc.gen.component table/head --namespace reporting
```

#### Props

Props are specified with `name:type:opts` where type is a valid Surface prop
type, and opts are one or more of `required`, `default`, `values`, `accumulate`.

Short-forms can be used for the props:

r == required
d == default
a == accumulate
v == values

If default is specified, it should be followed with the value in brackets.
If values is specified, it should be followed with a pipe-delimited list
of values in brackets.

```bash
mix sfc.gen.component Button rounded:boolean color:string:default[gray]
mix sfc.gen.component Button size:string:values[large,medium,small]
```

#### Slots

Slots can be specified with `--slot` switches.
For example:

```bash
mix sfc.gen.component Hero section:string --slot default:required --slot header --slot footer[section]
```

will add

```elixir
slot :default, required: true
slot :header
slot :footer, values: [:section]
```
