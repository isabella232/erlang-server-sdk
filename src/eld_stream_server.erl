%%%-------------------------------------------------------------------
%%% @doc Stream server
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(eld_stream_server).

-behaviour(gen_server).

%% Supervision
-export([start_link/0, init/1]).

%% Behavior callbacks
-export([code_change/3, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

%% API
-export([listen/4]).

-type state() :: #{conn => pid() | undefined}.

%%%===================================================================
%%% API
%%%===================================================================

%% @doc Start listening to streaming events
%%
%% @end
-spec listen(Pid :: pid(), Host :: string(), Port :: pos_integer(), Path :: string()) ->
    ok | {error, atom(), term()}.
listen(Pid, Host, Port, Path) when is_pid(Pid), is_integer(Port), Port > 0 ->
    gen_server:call(Pid, {listen, Host, Port, Path}).

%% @doc Starts the server
%%
%% @end
-spec start_link() ->
    {ok, Pid :: pid()} | ignore | {error, Reason :: term()}.
start_link() ->
    gen_server:start_link(?MODULE, [], []).

-spec init(Args :: term()) ->
    {ok, State :: state()} | {ok, State :: state(), timeout() | hibernate} |
    {stop, Reason :: term()} | ignore.
init([]) ->
    % Need to trap exit so supervisor:terminate_child calls terminate callback
    process_flag(trap_exit, true),
    {ok, #{conn => undefined}}.

%%%===================================================================
%%% Behavior callbacks
%%%===================================================================

-type from() :: {pid(), term()}.
-spec handle_call(Request :: term(), From :: from(), State :: state()) ->
    {reply, Reply :: term(), NewState :: state()} |
    {stop, normal, {error, atom(), term()}, state()}.
handle_call({listen, Host, Port, Path}, _From, State) ->
    case shotgun:open(Host, Port) of
        {error, gun_open_failed} ->
            {stop, normal, {error, gun_open_failed, "Could not open connection to host"}, State};
        {error, gun_open_timeout} ->
            {stop, normal, {error, gun_open_timeout, "Connection timeout"}, State};
        {ok, ShotgunPid} ->
            F = fun(nofin, _Ref, Bin) ->
                process_event(shotgun:parse_event(Bin))
                end,
            Options = #{async => true, async_mode => sse, handle_event => F},
            case shotgun:get(ShotgunPid, Path, #{}, Options) of
                {error, Reason} ->
                    {stop, normal, {error, get_req_failed, Reason}};
                {ok, _Ref} ->
                    {reply, ok, State#{conn := ShotgunPid}}
            end
    end.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

-spec terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: state()) -> term().
terminate(_Reason, #{conn := ShotgunPid} = _State) ->
    ok = shotgun:close(ShotgunPid).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% @doc Processes server-sent event received from shotgun
%%
%% @end
-spec process_event(shotgun:event()) -> ok.
process_event(#{event := Event, data := Data}) ->
    io:format("~nReceived event ~p with data ~p", [Event, Data]).