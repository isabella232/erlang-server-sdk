%%-------------------------------------------------------------------
%% @doc `eld_storage_map' module
%%
%% Provides implementation of storage backend using Erlang map.
%% @end
%%-------------------------------------------------------------------

-module(eld_storage_map).

-behaviour(eld_storage_engine).

%% Helper macro for declaring children of supervisor
-define(CHILD(Id, Module, Args, Type), {Id, {Module, start_link, Args}, permanent, 5000, Type, [Module]}).

%% Behavior callbacks
-export([init/3]).
-export([create/2]).
-export([empty/2]).
-export([get/3]).
-export([list/2]).
-export([put/3]).
-export([terminate/1]).

%%===================================================================
%% Behavior callbacks
%%===================================================================

-spec init(SupRef :: atom(), Tag :: atom(), Options :: list()) ->
    ok.
init(SupRef, Tag, _) ->
    StorageMapSup = ?CHILD(eld_storage_map_sup, eld_storage_map_sup, [Tag], supervisor),
    {ok, _} = supervisor:start_child(SupRef, StorageMapSup),
    % Pre-create flags and segments buckets
    ok = create(Tag, flags),
    ok = create(Tag, segments).

-spec create(Tag :: atom(), Bucket :: atom()) ->
    ok |
    {error, already_exists, string()}.
create(Tag, Bucket) ->
    ServerRef = eld_storage_map_server:get_local_reg_name(Tag),
    eld_storage_map_server:create(ServerRef, Bucket).

-spec empty(Tag :: atom(), Bucket :: atom()) ->
    ok |
    {error, bucket_not_found, string()}.
empty(Tag, Bucket) ->
    ServerRef = eld_storage_map_server:get_local_reg_name(Tag),
    eld_storage_map_server:empty(ServerRef, Bucket).

-spec get(Tag :: atom(), Bucket :: atom(), Key :: binary()) ->
    [{Key :: binary(), Value :: any()}] |
    {error, bucket_not_found, string()}.
get(Tag, Bucket, Key) ->
    ServerRef = eld_storage_map_server:get_local_reg_name(Tag),
    eld_storage_map_server:get(ServerRef, Bucket, Key).

-spec list(Tag :: atom(), Bucket :: atom()) ->
    [{Key :: binary(), Value :: any()}] |
    {error, bucket_not_found, string()}.
list(Tag, Bucket) ->
    ServerRef = eld_storage_map_server:get_local_reg_name(Tag),
    eld_storage_map_server:list(ServerRef, Bucket).

-spec put(Tag :: atom(), Bucket :: atom(), Items :: #{Key :: binary() => Value :: any()}) ->
    ok |
    {error, bucket_not_found, string()}.
put(Tag, Bucket, Items) ->
    ServerRef = eld_storage_map_server:get_local_reg_name(Tag),
    eld_storage_map_server:put(ServerRef, Bucket, Items).

-spec terminate(Tag :: atom()) -> ok.
terminate(Tag) ->
    StorageMapServerRef = eld_storage_map_server:get_local_reg_name(Tag),
    supervisor:terminate_child(eld_storage_map_sup, StorageMapServerRef).
