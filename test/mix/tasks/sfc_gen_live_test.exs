Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.LiveTest do
  use ExUnit.Case
  import MixHelper
  alias Mix.Tasks.Sfc.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  defp in_tmp_live_project(test, func) do
    in_tmp_project(test, fn ->
      File.mkdir_p!("lib")
      File.touch!("lib/sfc_gen_live_web.ex")
      File.touch!("lib/sfc_gen_live.ex")
      func.()
    end)
  end

  defp in_tmp_live_umbrella_project(test, func) do
    in_tmp_umbrella_project(test, fn ->
      File.mkdir_p!("sfc_gen_live/lib")
      File.mkdir_p!("sfc_gen_live_web/lib")
      File.touch!("sfc_gen_live/lib/sfc_gen_live.ex")
      File.touch!("sfc_gen_live_web/lib/sfc_gen_live_web.ex")
      func.()
    end)
  end

  test "invalid mix arguments", config do
    in_tmp_live_project(config.test, fn ->
      assert_raise Mix.Error, ~r/Expected the context, "blog", to be a valid module name/, fn ->
        Gen.Live.run(~w(blog Post posts title:string))
      end

      assert_raise Mix.Error, ~r/Expected the schema, "posts", to be a valid module name/, fn ->
        Gen.Live.run(~w(Post posts title:string))
      end

      assert_raise Mix.Error, ~r/The context and schema should have different names/, fn ->
        Gen.Live.run(~w(Blog Blog blogs))
      end

      assert_raise Mix.Error, ~r/Invalid arguments/, fn ->
        Gen.Live.run(~w(Blog.Post posts))
      end

      assert_raise Mix.Error, ~r/Invalid arguments/, fn ->
        Gen.Live.run(~w(Blog Post))
      end
    end)
  end

  test "generates live resource and handles existing contexts", config do
    in_tmp_live_project(config.test, fn ->
      Gen.Live.run(~w(Blog Post posts title slug:unique votes:integer cost:decimal
                      tags:array:text popular:boolean drafted_at:datetime
                      published_at:utc_datetime
                      published_at_usec:utc_datetime_usec
                      deleted_at:naive_datetime
                      deleted_at_usec:naive_datetime_usec
                      alarm:time
                      alarm_usec:time_usec
                      secret:uuid announcement_date:date
                      weight:float user_id:references:users))

      assert_file("lib/sfc_gen_live/blog/post.ex")
      assert_file("lib/sfc_gen_live/blog.ex")
      assert_file("test/sfc_gen_live/blog_test.exs")

      assert_file("lib/sfc_gen_live_web/live/post_live/index.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.PostLive.Index"
      end)

      assert_file("lib/sfc_gen_live_web/live/post_live/show.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.PostLive.Show"
      end)

      assert_file("lib/sfc_gen_live_web/live/post_live/form_component.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.PostLive.FormComponent"
      end)

      assert_file("lib/sfc_gen_live_web/components/modal.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Components.Modal"
      end)

      assert [path] = Path.wildcard("priv/repo/migrations/*_create_posts.exs")

      assert_file(path, fn file ->
        assert file =~ "create table(:posts)"
        assert file =~ "add :title, :string"
        assert file =~ "create unique_index(:posts, [:slug])"
      end)

      assert_file("lib/sfc_gen_live_web/live/post_live/index.sface", fn file ->
        assert file =~ " Routes.post_index_path(@socket, :index)"
      end)

      assert_file("lib/sfc_gen_live_web/live/post_live/show.sface", fn file ->
        assert file =~ " Routes.post_index_path(@socket, :index)"
      end)

      assert_file("lib/sfc_gen_live_web/live/post_live/form_component.sface", fn file ->
        assert file =~ ~s(<TextInput/>)
        assert file =~ ~s(<NumberInput/>)
        assert file =~ ~s(<NumberInput opts={{step: "any" }}/>)

        assert file =~
                 ~s(<MultipleSelect options={{ ["Option 1": "option1", "Option 2": "option2"] }}/>)

        assert file =~ ~s(<Checkbox/>)
        assert file =~ ~s(<DateTimeSelect/>)
        assert file =~ ~s(<DateSelect/>)
        assert file =~ ~s(<TimeSelect/>)
        assert file =~ ~s(<TextInput/>)

        assert file =~ ~s(<Field name="title">)
        assert file =~ ~s(<Field name="votes">)
        assert file =~ ~s(<Field name="cost">)
        assert file =~ ~s(<Field name="tags">)
        assert file =~ ~s(<Field name="popular">)
        assert file =~ ~s(<Field name="drafted_at">)
        assert file =~ ~s(<Field name="published_at">)
        assert file =~ ~s(<Field name="deleted_at">)
        assert file =~ ~s(<Field name="announcement_date">)
        assert file =~ ~s(<Field name="alarm">)
        assert file =~ ~s(<Field name="secret">)

        refute file =~ ~s(<Field name="user_id">)
      end)

      send(self(), {:mix_shell_input, :yes?, true})
      Gen.Live.run(~w(Blog Comment comments title:string))
      assert_received {:mix_shell, :info, ["You are generating into an existing context" <> _]}

      assert_file("lib/sfc_gen_live/blog/comment.ex")

      assert_file("test/sfc_gen_live_web/live/comment_live_test.exs", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.CommentLiveTest"
      end)

      assert [path] = Path.wildcard("priv/repo/migrations/*_create_comments.exs")

      assert_file(path, fn file ->
        assert file =~ "create table(:comments)"
        assert file =~ "add :title, :string"
      end)

      assert_file("lib/sfc_gen_live_web/live/comment_live/index.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.CommentLive.Index"
      end)

      assert_file("lib/sfc_gen_live_web/live/comment_live/show.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.CommentLive.Show"
      end)

      assert_file("lib/sfc_gen_live_web/live/comment_live/form_component.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.CommentLive.FormComponent"
      end)

      assert_file("lib/sfc_gen_live_web.ex", fn file ->
        assert file =~ "def surface_view do"
        assert file =~ "def surface_component do"
      end)

      assert_receive {:mix_shell, :info,
                      [
                        """

                        Add the live routes to your browser scope in lib/sfc_gen_live_web/router.ex:

                            live "/comments", CommentLive.Index, :index
                            live "/comments/new", CommentLive.Index, :new
                            live "/comments/:id/edit", CommentLive.Index, :edit

                            live "/comments/:id", CommentLive.Show, :show
                            live "/comments/:id/show/edit", CommentLive.Show, :edit
                        """
                      ]}
    end)
  end

  test "with --web namespace generates namespaced web modules and directories", config do
    in_tmp_live_project(config.test, fn ->
      Gen.Live.run(~w(Blog Post posts title:string --web Blog))

      assert_file("lib/sfc_gen_live/blog/post.ex")
      assert_file("lib/sfc_gen_live/blog.ex")
      assert_file("test/sfc_gen_live/blog_test.exs")

      assert_file("lib/sfc_gen_live_web/live/blog/post_live/index.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Blog.PostLive.Index"
      end)

      assert_file("lib/sfc_gen_live_web/live/blog/post_live/show.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Blog.PostLive.Show"
      end)

      assert_file("lib/sfc_gen_live_web/live/blog/post_live/form_component.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Blog.PostLive.FormComponent"
      end)

      assert_file("lib/sfc_gen_live_web/components/modal.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Components.Modal"
      end)

      assert [path] = Path.wildcard("priv/repo/migrations/*_create_posts.exs")

      assert_file(path, fn file ->
        assert file =~ "create table(:posts)"
        assert file =~ "add :title, :string"
      end)

      assert_file("lib/sfc_gen_live_web/live/blog/post_live/index.sface", fn file ->
        assert file =~ " Routes.blog_post_index_path(@socket, :index)"
        assert file =~ " Routes.blog_post_index_path(@socket, :edit, post)"
        assert file =~ " Routes.blog_post_index_path(@socket, :new)"
        assert file =~ " Routes.blog_post_show_path(@socket, :show, post)"
      end)

      assert_file("lib/sfc_gen_live_web/live/blog/post_live/show.sface", fn file ->
        assert file =~ " Routes.blog_post_index_path(@socket, :index)"
        assert file =~ " Routes.blog_post_show_path(@socket, :show, @post)"
        assert file =~ " Routes.blog_post_show_path(@socket, :edit, @post)"
      end)

      assert_file("lib/sfc_gen_live_web/live/blog/post_live/form_component.sface")

      assert_file("test/sfc_gen_live_web/live/blog/post_live_test.exs", fn file ->
        assert file =~ " Routes.blog_post_index_path(conn, :index)"
        assert file =~ " Routes.blog_post_index_path(conn, :new)"
        assert file =~ " Routes.blog_post_show_path(conn, :show, post)"
        assert file =~ " Routes.blog_post_show_path(conn, :edit, post)"
      end)

      assert_receive {:mix_shell, :info,
                      [
                        """

                        Add the live routes to your Blog :browser scope in lib/sfc_gen_live_web/router.ex:

                            scope "/blog", SfcGenLiveWeb.Blog, as: :blog do
                              pipe_through :browser
                              ...

                              live "/posts", PostLive.Index, :index
                              live "/posts/new", PostLive.Index, :new
                              live "/posts/:id/edit", PostLive.Index, :edit

                              live "/posts/:id", PostLive.Show, :show
                              live "/posts/:id/show/edit", PostLive.Show, :edit
                            end
                        """
                      ]}
    end)
  end

  test "with --no-context skips context and schema file generation", config do
    in_tmp_live_project(config.test, fn ->
      Gen.Live.run(~w(Blog Post posts title:string --no-context))

      refute_file("lib/sfc_gen_live/blog.ex")
      refute_file("lib/sfc_gen_live/blog/post.ex")
      assert Path.wildcard("priv/repo/migrations/*.exs") == []

      assert_file("lib/sfc_gen_live_web/live/post_live/index.ex")
      assert_file("lib/sfc_gen_live_web/live/post_live/show.ex")
      assert_file("lib/sfc_gen_live_web/live/post_live/form_component.ex")

      assert_file("lib/sfc_gen_live_web/components/modal.ex", fn file ->
        assert file =~ "defmodule SfcGenLiveWeb.Components.Modal"
      end)

      assert_file("lib/sfc_gen_live_web/live/post_live/index.sface")
      assert_file("lib/sfc_gen_live_web/live/post_live/show.sface")
      assert_file("lib/sfc_gen_live_web/live/post_live/form_component.sface")
      assert_file("test/sfc_gen_live_web/live/post_live_test.exs")
    end)
  end

  test "with --no-schema skips schema file generation", config do
    in_tmp_live_project(config.test, fn ->
      Gen.Live.run(~w(Blog Post posts title:string --no-schema))

      assert_file("lib/sfc_gen_live/blog.ex")
      refute_file("lib/sfc_gen_live/blog/post.ex")
      assert Path.wildcard("priv/repo/migrations/*.exs") == []

      assert_file("lib/sfc_gen_live_web/live/post_live/index.ex")
      assert_file("lib/sfc_gen_live_web/live/post_live/show.ex")
      assert_file("lib/sfc_gen_live_web/live/post_live/form_component.ex")
      assert_file("lib/sfc_gen_live_web/components/modal.ex")

      assert_file("lib/sfc_gen_live_web/live/post_live/index.sface")
      assert_file("lib/sfc_gen_live_web/live/post_live/show.sface")
      assert_file("lib/sfc_gen_live_web/live/post_live/form_component.sface")
      assert_file("test/sfc_gen_live_web/live/post_live_test.exs")
    end)
  end

  test "with same singular and plural", config do
    in_tmp_live_project(config.test, fn ->
      Gen.Live.run(~w(Tracker Series series value:integer))

      assert_file("lib/sfc_gen_live/tracker.ex")
      assert_file("lib/sfc_gen_live/tracker/series.ex")

      assert_file("lib/sfc_gen_live_web/live/series_live/index.ex", fn file ->
        assert file =~ "assign(socket, :series_collection, list_series())"
      end)

      assert_file("lib/sfc_gen_live_web/live/series_live/show.ex")
      assert_file("lib/sfc_gen_live_web/live/series_live/form_component.ex")
      assert_file("lib/sfc_gen_live_web/components/modal.ex")

      assert_file("lib/sfc_gen_live_web/live/series_live/index.sface", fn file ->
        assert file =~ ":for={{ series <- @series_collection }}"
      end)

      assert_file("lib/sfc_gen_live_web/live/series_live/show.sface")
      assert_file("lib/sfc_gen_live_web/live/series_live/form_component.sface")
      assert_file("test/sfc_gen_live_web/live/series_live_test.exs")
    end)
  end

  describe "inside umbrella" do
    test "without context_app generators config uses web dir", config do
      in_tmp_live_umbrella_project(config.test, fn ->
        File.cd!("sfc_gen_live_web")

        Application.put_env(:sfc_gen_live, :generators, context_app: nil)
        Gen.Live.run(~w(Accounts User users name:string))

        assert_file("lib/sfc_gen_live/accounts.ex")
        assert_file("lib/sfc_gen_live/accounts/user.ex")

        assert_file("lib/sfc_gen_live_web/live/user_live/index.ex", fn file ->
          assert file =~ "defmodule SfcGenLiveWeb.UserLive.Index"
          assert file =~ "use SfcGenLiveWeb, :surface_view"
        end)

        assert_file("lib/sfc_gen_live_web/live/user_live/show.ex", fn file ->
          assert file =~ "defmodule SfcGenLiveWeb.UserLive.Show"
          assert file =~ "use SfcGenLiveWeb, :surface_view"
        end)

        assert_file("lib/sfc_gen_live_web/live/user_live/form_component.ex", fn file ->
          assert file =~ "defmodule SfcGenLiveWeb.UserLive.FormComponent"
          assert file =~ "use SfcGenLiveWeb, :surface_component"
        end)

        assert_file("lib/sfc_gen_live_web/live/user_live/form_component.sface")

        assert_file("lib/sfc_gen_live_web/components/modal.ex", fn file ->
          assert file =~ "defmodule SfcGenLiveWeb.Components.Modal"
        end)

        assert_file("test/sfc_gen_live_web/live/user_live_test.exs", fn file ->
          assert file =~ "defmodule SfcGenLiveWeb.UserLiveTest"
        end)
      end)
    end

    test "raises with false context_app", config do
      in_tmp_live_umbrella_project(config.test, fn ->
        Application.put_env(:sfc_gen_live, :generators, context_app: false)

        assert_raise Mix.Error, ~r/no context_app configured/, fn ->
          Gen.Live.run(~w(Accounts User users name:string))
        end
      end)
    end

    test "with context_app generators config does not use web dir", config do
      in_tmp_live_umbrella_project(config.test, fn ->
        File.mkdir!("another_app")

        Application.put_env(:sfc_gen_live, :generators, context_app: {:another_app, "another_app"})

        File.cd!("sfc_gen_live")

        Gen.Live.run(~w(Accounts User users name:string))

        assert_file("another_app/lib/another_app/accounts.ex")
        assert_file("another_app/lib/another_app/accounts/user.ex")

        assert_file("lib/sfc_gen_live/live/user_live/index.ex", fn file ->
          assert file =~ "defmodule SfcGenLive.UserLive.Index"
          assert file =~ "use SfcGenLive, :surface_view"
        end)

        assert_file("lib/sfc_gen_live/live/user_live/show.ex", fn file ->
          assert file =~ "defmodule SfcGenLive.UserLive.Show"
          assert file =~ "use SfcGenLive, :surface_view"
        end)

        assert_file("lib/sfc_gen_live/live/user_live/form_component.ex", fn file ->
          assert file =~ "defmodule SfcGenLive.UserLive.FormComponent"
          assert file =~ "use SfcGenLive, :surface_component"
        end)

        assert_file("lib/sfc_gen_live/components/modal.ex", fn file ->
          assert file =~ "defmodule SfcGenLive.Components.Modal"
        end)

        assert_file("lib/sfc_gen_live/live/user_live/form_component.sface")

        assert_file("test/sfc_gen_live/live/user_live_test.exs", fn file ->
          assert file =~ "defmodule SfcGenLive.UserLiveTest"
        end)
      end)
    end
  end
end
