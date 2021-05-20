defmodule Mix.SfcGenLive do
  @moduledoc false

  @cli_theme_bg 32
  @cli_theme_fg 15

  alias Mix.Surface.Component.Code

  @doc """
  The paths to look for template files for generators.

  Defaults to checking the current app's `priv` directory,
  and falls back to Phoenix's `priv` directory.
  """
  def generator_paths do
    [".", :sfc_gen_live, :phoenix]
  end

  # this
  @spec put_context_app(keyword, nil | binary) :: [{atom, any}, ...]
  def put_context_app(opts, nil) do
    Keyword.put(opts, :context_app, Mix.Phoenix.context_app())
  end

  def put_context_app(opts, string) do
    Keyword.put(opts, :context_app, String.to_atom(string))
  end

  def valid_namespace?(name) when is_binary(name) do
    name
    |> split_name()
    |> valid_namespace?()
  end

  def valid_namespace?(namespace_parts) when is_list(namespace_parts) do
    Enum.all?(namespace_parts, &valid_module?/1)
  end

  def split_name(name) do
    name
    |> Phoenix.Naming.underscore()
    |> String.split("/", trim: true)
  end

  def web_module_path(ctx_app) do
    web_prefix = Mix.Phoenix.web_path(ctx_app)
    [lib_prefix, web_dir] = Path.split(web_prefix)
    Path.join(lib_prefix, "#{web_dir}.ex")
  end

  def web_test_path(ctx_app) do
    web_prefix = Mix.Phoenix.web_path(ctx_app)
    [_lib_prefix, web_dir] = Path.split(web_prefix)
    Path.join("test", web_dir)
  end

  def inflect(namespace_parts, name, context_app \\ nil)

  def inflect(namespace_parts, name, context_app) when is_nil(context_app),
    do: inflect(namespace_parts, name, Mix.Phoenix.context_app())

  def inflect(namespace_parts, name, context_app) when is_binary(name),
    do: inflect(namespace_parts, String.split(name, "/"), context_app)

  def inflect(namespace_parts, name_parts, context_app) do
    path = Enum.concat(namespace_parts, name_parts) |> Enum.join("/")
    web_path = Mix.Phoenix.web_path(context_app)
    base = Module.concat([Mix.Phoenix.base()])
    web_module = base |> Mix.Phoenix.web_module()
    web_module_path = web_module_path(context_app)

    scoped = path |> Phoenix.Naming.camelize()
    namespace_module = Module.concat(namespace_parts |> Enum.map(&Phoenix.Naming.camelize/1))
    module = Module.concat(web_module, scoped)
    alias = Module.concat([Module.split(module) |> List.last()])
    human = Enum.map(name_parts, &Phoenix.Naming.humanize/1) |> Enum.join(" ")

    test_root = web_test_path(context_app)
    test_dir = Path.join([test_root] ++ namespace_parts ++ Enum.slice(name_parts, 0..-2))
    test_filename = List.last(name_parts) <> "_test.exs"
    test_path = Path.join(test_dir, test_filename)

    [
      alias: alias,
      human: human,
      web_module: web_module,
      web_module_path: web_module_path,
      namespace_module: namespace_module,
      module: module,
      path: path,
      web_path: web_path,
      test_root: test_root,
      test_path: test_path
    ]
    |> IO.inspect(label: "inflect")
  end

  @doc """
  Finds blocks of code matching `fragment` and adds insert at position :start, :end or :after
  each matching block of code IFF the block of code does not already contain insert at _any_ of
  said positions.

  You can also pass `:quote` for position, and the insert will be at the end of the first
  **multiline** `quote do...end` block in the matching block.

  Relies on the code being canonically formatted and the fragment needs to start with the
  first non-whitespace character on a line it should match, or lea͠ki̧n͘g fr̶ǫm ̡yo​͟ur eye͢s̸
  ̛l̕ik͏e liq​uid pain, the song of re̸gular exp​ression parsing will exti​nguish the voices of
  mor​tal man from the sp​here I can see it can you see ̲͚̖͔̙î̩́t̲͎̩̱͔́̋̀ it is beautiful t​he
  final snuffing of the lie​s of Man ALL IS LOŚ͖̩͇̗̪̏̈́T ALL I​S LOST the pon̷y he comes he
  c̶̮omes he comes the ich​or permeates all MY FACE MY FACE ᵒh god no NO NOO̼O​O NΘ stop the
  an​*̶͑̾̾​̅ͫ͏̙̤g͇̫͛͆̾ͫ̑͆l͖͉̗̩̳̟̍ͫͥͨe̠̅s ͎a̧͈͖r̽̾̈́͒͑e n​ot rè̑ͧ̌aͨl̘̝̙̃ͤ͂̾̆ ZA̡͊͠͝LGΌ
  ISͮ̂҉̯͈͕̹̘̱ TO͇̹̺ͅƝ̴ȳ̳ TH̘Ë͖́̉ ͠P̯͍̭O̚​N̐Y̡ H̸̡̪̯ͨ͊̽̅̾̎Ȩ̬̩̾͛ͪ̈́̀́͘
  ̶̧̨̱̹̭̯ͧ̾ͬC̷̙̲̝͖ͭ̏ͥͮ͟Oͮ͏̮̪̝͍M̲̖͊̒ͪͩͬ̚̚͜Ȇ̴̟̟͙̞ͩ͌͝S̨̥̫͎̭ͯ̿̔̀ͅ
  """
  def insert_in_blocks_matching_fragment(
        file,
        fragment,
        insert,
        position \\ :start,
        how_many \\ :all
      )

  def insert_in_blocks_matching_fragment(file, fragment, insert, at, how_many)
      when is_binary(fragment) do
    insert_in_blocks_matching_fragment(
      file,
      ~r/#{Regex.escape(fragment)}/,
      insert,
      at,
      how_many
    )
  end

  def insert_in_blocks_matching_fragment(
        file,
        %Regex{} = fragment,
        insert,
        at,
        how_many
      ) do
    # I cannot figure out why the extended regex doesn't work
    block_match = ~r/
      ^(?<indent>\ *)(?<start>
         #{Regex.source(fragment)}
         .*[\n]
       )
       (?<guts>
         (?:
           (?:^\k<indent>\ +.*[\n]) | (?:^\s*[\n])
         )*
       )
       (?<end>
         ^\k<indent>end\ *[\n]   # this part doesn't match, don't know why!!!!
       )/mx

    # block_match =
    #   ~r/^(?<indent> *)(?<start>#{Regex.source(fragment)}.*\n)(?<guts>(?:(?:^\k<indent>\ +.*\n)|(?:^\s*\n))*)(?<end>^\k<indent>end *\n)/m

    num_parts =
      case how_many do
        :all ->
          :infinity

        :first ->
          5
      end

    parts =
      Regex.split(
        block_match,
        file,
        include_captures: true,
        on: [:indent, :start, :guts, :end],
        trim: true,
        parts: num_parts
      )

    {start, matches} =
      cond do
        Regex.match?(~r/#{Regex.source(fragment)}/, Enum.at(parts, 1)) ->
          {"", parts}

        true ->
          {hd(parts), tl(parts)}
      end

    Enum.join([
      start,
      matches
      |> Enum.chunk_every(5)
      |> Enum.map(fn m -> insert_in_block_matches(m, insert, at) end)
      |> Enum.join()
    ])
  end

  defp insert_in_block_matches([], _insert, _at), do: ""

  defp insert_in_block_matches(matches, "", _at),
    do: Enum.join(matches)

  defp insert_in_block_matches(matches, insert, :quote) do
    Enum.join(
      # ["sure but why?"] ++
      # ["lets descend"] ++
      # ["back out"] ++

      Enum.take(matches, 2) ++
        [
          insert_in_blocks_matching_fragment(
            Enum.at(matches, 2),
            "quote do",
            insert,
            :end,
            :first
          )
        ] ++
        Enum.slice(matches, 3..-1)
      # ["dunno :("]
    )
  end

  defp insert_in_block_matches(matches, insert, at) do
    insert_index =
      case at do
        :start -> 2
        :end -> 3
        :after -> 4
      end

    cond do
      Enum.any?(matches, fn match -> String.contains?(match, insert) end) ->
        Enum.join(matches)

      true ->
        matches
        |> List.insert_at(insert_index, indent_insert(insert, hd(matches), at))
        |> Enum.join()
    end
  end

  defp indent_insert(insert, indent, :start),
    do: indent <> "  " <> String.trim(insert) <> "\n\n"

  defp indent_insert(insert, indent, :end),
    do: "\n" <> indent <> "  " <> String.trim(insert) <> "\n"

  defp indent_insert(insert, indent, :after),
    do: "\n" <> indent <> String.trim(insert) <> "\n"

  defp valid_module?(name) do
    Phoenix.Naming.camelize(name) =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  def inspect_string_list(strlist) do
    strlist |> Enum.with_index() |> Enum.each(fn {x, i} -> IO.puts("#{i} ---------\n`#{x}`") end)
  end

  def print_version_banner(task, opts) do
    version = Application.spec(:sfc_gen_live, :vsn) |> to_string

    task = task |> to_string() |> String.replace_leading("Elixir.Mix.Tasks.", "")

    unless opts[:quiet] do
      text = theme(" #{to_string(task)}  v#{version} ")
      IO.puts(text)
    end
  end

  def theme(text) do
    IO.ANSI.color_background(@cli_theme_bg) <>
      IO.ANSI.color(@cli_theme_fg) <> text <> IO.ANSI.reset()
  end

  @spec update_from(any, any, any, maybe_improper_list) :: list
  def update_from(apps, source_dir, binding, mapping) when is_list(mapping) do
    roots = Enum.map(apps, &to_app_source(&1, source_dir))

    for {format, source_file_path, target} <- mapping do
      source =
        Enum.find_value(roots, fn root ->
          source = Path.join(root, source_file_path)
          if File.exists?(source), do: source
        end) || raise "could not find #{source_file_path} in any of the sources"

      case format do
        :text ->
          Mix.Generator.create_file(target, File.read!(source))

        :eex ->
          if File.exists?(target) do
            Code.update_component_file(target, binding)
          else
            Mix.Generator.create_file(target, EEx.eval_file(source, binding))
          end

        :new_eex ->
          if File.exists?(target) do
            :ok
          else
            Mix.Generator.create_file(target, EEx.eval_file(source, binding))
          end
      end
    end
  end

  defp to_app_source(path, source_dir) when is_binary(path),
    do: Path.join(path, source_dir)

  defp to_app_source(app, source_dir) when is_atom(app),
    do: Application.app_dir(app, source_dir)
end
