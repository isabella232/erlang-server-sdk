%%-------------------------------------------------------------------
%% @doc `eld_storage_ets_server' module
%%
%% This is a simple in-memory implementation of an storage server using ETS.
%% @end
%%-------------------------------------------------------------------

-module(eld_storage_ets_server).

-behaviour(gen_server).

%% Supervision
-export([start_link/1, init/1]).

%% Behavior callbacks
-export([code_change/3, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

%% API
-export([create/2]).
-export([empty/2]).
-export([get/3]).
-export([list/2]).
-export([put/3]).
-export([get_local_reg_name/1]).

%% Types
-type state() :: map().

%%===================================================================
%% Supervision
%%===================================================================

start_link(Tag) ->
    io:format("Starting ets server with name: ~p~n", [get_local_reg_name(Tag)]),
    gen_server:start_link({local, get_local_reg_name(Tag)}, ?MODULE, [], []).

init([]) ->
    {ok, #{}}.

%%===================================================================
%% API
%%===================================================================

%% @doc Create a bucket
%%
%% @end
-spec create(ServerRef :: atom(), Bucket :: atom()) ->
    ok |
    {error, already_exists, string()}.
create(ServerRef, Bucket) when is_atom(Bucket) ->
    gen_server:call(ServerRef, {create, Bucket}).

%% @doc Empty a bucket
%%
%% @end
-spec empty(ServerRef :: atom(), Bucket :: atom()) ->
    ok |
    {error, bucket_not_found, string()}.
empty(ServerRef, Bucket) when is_atom(Bucket) ->
    gen_server:call(ServerRef, {empty, Bucket}).

%% @doc Get an item from the bucket by its key
%%
%% @end
-spec get(ServerRef :: atom(), Bucket :: atom(), Key :: binary()) ->
    [{Key :: binary(), Value :: any()}] |
    {error, bucket_not_found, string()}.
get(ServerRef, Bucket, Key) when is_atom(Bucket), is_binary(Key) ->
    gen_server:call(ServerRef, {get, Bucket, Key}).

%% @doc List all items in a bucket
%%
%% @end
-spec list(ServerRef :: atom(), Bucket :: atom()) ->
    [{Key :: binary(), Value :: any()}] |
    {error, bucket_not_found, string()}.
list(ServerRef, Bucket) when is_atom(Bucket) ->
    gen_server:call(ServerRef, {list, Bucket}).

%% @doc Put an item key value pair in an existing bucket
%%
%% @end
-spec put(ServerRef :: atom(), Bucket :: atom(), Items :: #{Key :: binary() => Value :: any()}) ->
    ok |
    {error, bucket_not_found, string()}.
put(ServerRef, Bucket, Items) when is_atom(Bucket), is_map(Items) ->
    ok = gen_server:call(ServerRef, {put, Bucket, Items}).

-spec get_local_reg_name(Tag :: atom()) -> atom().
get_local_reg_name(Tag) ->
    list_to_atom(atom_to_list(?MODULE) ++ "_" ++ atom_to_list(Tag)).

%%===================================================================
%% Behavior callbacks
%%===================================================================

-type from() :: {pid(), term()}.
-spec handle_call(term(), from(), state()) -> {reply, term(), state()}.
handle_call({create, Bucket}, _From, State) ->
    {reply, create_bucket(Bucket), State};
handle_call({empty, Bucket}, _From, State) ->
    {reply, empty_bucket(Bucket), State};
handle_call({get, Bucket, Key}, _From, State) ->
    {reply, lookup_key(Key, Bucket), State};
handle_call({list, Bucket}, _From, State) ->
    {reply, list_items(Bucket), State};
handle_call({put, Bucket, Item}, _From, State) ->
    {reply, put_items(Item, Bucket), State}.

handle_cast(_Msg, State) -> {noreply, State}.

handle_info(_Msg, State) -> {noreply, State}.

terminate(_Reason, _State) -> ok.

code_change(_OldVersion, State, _Extra) -> {ok, State}.

%%===================================================================
%% Internal functions
%%===================================================================

%% @doc Check whether bucket already exists
%% @private
%%
%% @end
-spec bucket_exists(Bucket :: atom()) -> boolean().
bucket_exists(Bucket) when is_atom(Bucket) ->
    case ets:info(Bucket) of
        undefined -> false;
        _ -> true
    end.

%% @doc Create a bucket
%% @private
%%
%% If bucket with the same name already exists an error will be returned.
%% @end
-spec create_bucket(Bucket :: atom()) ->
    ok |
    {error, already_exists, string()}.
create_bucket(Bucket) when is_atom(Bucket) ->
    case bucket_exists(Bucket) of
        false ->
            Bucket = ets:new(Bucket, [set, named_table]),
            ok;
        _ ->
            {error, already_exists, "ETS table " ++ atom_to_list(Bucket) ++ " already exists."}
    end.

%% @doc Empty a bucket
%% @private
%%
%% If no such bucket exists, error will be returned.
%% @end
-spec empty_bucket(Bucket :: atom()) ->
    ok |
    {error, bucket_not_found, string()}.
empty_bucket(Bucket) when is_atom(Bucket) ->
    case bucket_exists(Bucket) of
        false ->
            {error, bucket_not_found, "ETS table " ++ atom_to_list(Bucket) ++ " does not exist."};
        _ ->
            true = ets:delete_all_objects(Bucket),
            ok
    end.

%% @doc List all items in a bucket
%% @private
%%
%% Returns all items stored in the bucket.
%% @end
-spec list_items(Bucket :: atom()) ->
    [tuple()] |
    {error, bucket_not_found, string()}.
list_items(Bucket) when is_atom(Bucket) ->
    case bucket_exists(Bucket) of
        false ->
            {error, bucket_not_found, "ETS table " ++ atom_to_list(Bucket) ++ " does not exist."};
        _ ->
            ets:tab2list(Bucket)
    end.

%% @doc Look up an item by key
%% @private
%%
%% Search for an item by its key.
%% @end
-spec lookup_key(Key :: binary(), Bucket :: atom()) ->
    [tuple()] |
    {error, bucket_not_found, string()}.
lookup_key(Key, Bucket) when is_atom(Bucket), is_binary(Key) ->
    case bucket_exists(Bucket) of
        false ->
            {error, bucket_not_found, "ETS table " ++ atom_to_list(Bucket) ++ " does not exist."};
        _ ->
            ets:lookup(Bucket, Key)
    end.

%% @doc Put a key value pair in bucket
%% @private
%%
%% @end
-spec put_items(Items :: #{Key :: binary() => Value :: any()}, Bucket :: atom()) ->
    ok |
    {error, bucket_not_found, string()}.
put_items(Items, Bucket) when is_map(Items), is_atom(Bucket) ->
    case bucket_exists(Bucket) of
        false ->
            {error, bucket_not_found, "ETS table " ++ atom_to_list(Bucket) ++ " does not exist."};
        _ ->
            true = ets:insert(Bucket, maps:to_list(Items)),
            ok
    end.
