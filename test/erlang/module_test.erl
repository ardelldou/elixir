-module(module_test).
-include_lib("eunit/include/eunit.hrl").

%% Module functions
%% TODO Assert 1 + module Foo or A = module Foo does not work

module_body_is_executable_test() -> 
  F = fun() ->
    ?assertError({unbound_var, a}, elixir:eval("module Foo; a; end")),
    elixir:eval("module Bar; 1 + 2; end")
  end,
  run_and_purge(F, ['Bar']).

module_are_converted_into_erlang_modules_test() ->
  F = fun() ->
    elixir:eval("module Bar; 1 + 2; end"),
    {file, "nofile"} = code:is_loaded('Bar')
  end,
  run_and_purge(F, ['Bar']).

module_preceeded_by_other_expressions_test() ->
  F = fun() ->
    elixir:eval("1 + 2\nmodule Bar; 1 + 2; end"),
    {file, "nofile"} = code:is_loaded('Bar')
  end,
  run_and_purge(F, ['Bar']).

module_with_methods_test() ->
  F = fun() ->
    elixir:eval("module Bar; def foo(); 1 + 2; end; end"),
    ?assertEqual(3, 'Bar':foo(self))
  end,
  run_and_purge(F, ['Bar']).

nested_modules_with_methods_test() ->
  F = fun() ->
    elixir:eval("module Bar; module Baz; def foo(); 1 + 2; end; end; end"),
    ?assertEqual(3, 'Bar::Baz':foo(self))
  end,
  run_and_purge(F, ['Bar', 'Bar::Baz']).

nested_module_name_with_methods_test() ->
  F = fun() ->
    elixir:eval("module Bar::Baz; def foo(); 1 + 2; end; end"),
    ?assertEqual(3, 'Bar::Baz':foo(self))
  end,
  run_and_purge(F, ['Bar::Baz']).

%% Prototype handling
%% TODO This is going to be removed as soon as we have the object model in place

prototype_with_method_invocation_test() ->
  F = fun() ->
    elixir:eval("prototype Integer; def some_value(); 23; end; end"),
    ?assertEqual({23,[]}, elixir:eval("1.some_value"))
  end,
  run_and_purge(F, ['@Integer']).

prototype_with_self_result_test() ->
  F = fun() ->
    elixir:eval("prototype Integer; def some_value(x); self + x; end; end"),
    ?assertEqual({25,[]}, elixir:eval("23.some_value(2)"))
  end,
  run_and_purge(F, ['@Integer']).

% Execute a piece of code and purge given modules right after
run_and_purge(Fun, Modules) ->
  try
    Fun()
  after
    [remove_module(Module) || Module <- Modules]
  end.

remove_module(Module) ->
  code:purge(Module),
  ets:delete(ex_constants, Module).

% Helper to load files
read_fixture(Filename) ->
  Dirname = filename:dirname(?FILE),
  Fullpath = filename:join([Dirname, "fixtures", Filename]),
  {ok, Bin} = file:read_file(Fullpath),
  binary_to_list(Bin).