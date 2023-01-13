%
% Copyright (c) 2016-2019 Petr Gotthard <petr.gotthard@centrum.cz>
% All rights reserved.
% Distributed under the terms of the MIT License. See the LICENSE file.
%
-module(lorawan_admin_choices).

-export([init/2]).
-export([allowed_methods/2]).
-export([is_authorized/2]).
-export([forbidden/2]).
-export([content_types_provided/2]).
-export([resource_exists/2]).

-export([handle_get/2]).

-include("lorawan_db.hrl").
-record(state, {name, scopes, auth_fields}).

init(Req, {Name, Scopes}) ->
    {cowboy_rest, Req, #state{name=Name, scopes=Scopes}}.

allowed_methods(Req, Opts) ->
    {[<<"OPTIONS">>, <<"GET">>], Req, Opts}.

is_authorized(Req, #state{scopes=Scopes}=State) ->
    case lorawan_admin:handle_authorization(Req, Scopes) of
        {true, AuthFields} ->
            {true, Req, State#state{auth_fields=AuthFields}};
        Else ->
            {Else, Req, State}
    end.

forbidden(Req, #state{auth_fields=AuthFields}=State) ->
    {lorawan_admin:fields_empty(AuthFields), Req, State}.

content_types_provided(Req, State) ->
    {[
        {{<<"application">>, <<"json">>, []}, handle_get}
    ], Req, State}.

handle_get(Req, #state{name=regions}=State) ->
    Regs =
        lists:map(
            fun(Region) ->
                {Region, [
                    {uplink_datar, uplink_datar_choices0(Region)},
                    {downlink_datar, downlink_datar_choices0(Region)}
                ]}
            end,
            [<<"EU868">>, <<"CN779">>, <<"EU433">>, <<"AS923">>, <<"CN470">>,
            <<"KR920">>, <<"IN865">>, <<"RU868">>,
            <<"US902">>, <<"US902-PR">>, <<"AU915">>]),
    {jsx:encode(Regs), Req, State};
handle_get(Req, #state{name=groups}=State) ->
    Nets =
        lists:map(
            fun(Group) ->
                {Group, group_choices(Group)}
            end,
            mnesia:dirty_all_keys(group)),
    {jsx:encode(Nets), Req, State};
handle_get(Req, #state{name=profiles}=State) ->
    Profs =
        lists:map(
            fun(Prof) ->
                [#profile{group=Group}] = mnesia:dirty_read(profile, Prof),
                {Prof, group_choices(Group)}
            end,
            mnesia:dirty_all_keys(profile)),
    {jsx:encode(Profs), Req, State}.

group_choices(Group) ->
    case mnesia:dirty_read(group, Group) of
        [#group{network=Net}] when is_binary(Net), byte_size(Net) > 0 ->
            network_choices(Net);
        _Else ->
            []
    end.

network_choices(Net) ->
    case mnesia:dirty_read(network, Net) of
        [#network{region=Region, max_eirp=Max, min_power=Min}] ->
            [
                {uplink_datar, uplink_datar_choices0(Region)},
                {downlink_datar, downlink_datar_choices0(Region)},
                {power, power_choices0(0, Max, Min)}
            ];
        _Else ->
            []
    end.

uplink_datar_choices0(Region) ->
    if
        Region == <<"US902">>; Region == <<"US902-PR">> -> [
            [{value, 0}, {label, <<"SF10 125 kHz (980 bit/s)">>}],
            [{value, 1}, {label, <<"SF9 125 kHz (1760 bit/s)">>}],
            [{value, 2}, {label, <<"SF8 125 kHz (3125 bit/s)">>}],
            [{value, 3}, {label, <<"SF7 125 kHz (5470 bit/s)">>}],
            [{value, 4}, {label, <<"SF8 500 kHz (12500 bit/s)">>}]];
        Region == <<"AU915">> -> [
            [{value, 0}, {label, <<"SF12 125 kHz (250 bit/s)">>}],
            [{value, 1}, {label, <<"SF11 125 kHz (440 bit/s)">>}],
            [{value, 2}, {label, <<"SF10 125 kHz (980 bit/s)">>}],
            [{value, 3}, {label, <<"SF9 125 kHz (1760 bit/s)">>}],
            [{value, 4}, {label, <<"SF8 125 kHz (3125 bit/s)">>}],
            [{value, 5}, {label, <<"SF7 125 kHz (5470 bit/s)">>}],
            [{value, 6}, {label, <<"SF8 500 kHz (12500 bit/s)">>}]];
        true ->
            both_datar_choices0(Region)
    end.

downlink_datar_choices0(Region) ->
    if
        Region == <<"US902">>; Region == <<"US902-PR">>; Region == <<"AU915">> -> [
            [{value, 8}, {label, <<"SF12 500 kHz (980 bit/s)">>}],
            [{value, 9}, {label, <<"SF11 500 kHz (1760 bit/s)">>}],
            [{value, 10}, {label, <<"SF10 500 kHz (3900 bit/s)">>}],
            [{value, 11}, {label, <<"SF9 500 kHz (7000 bit/s)">>}],
            [{value, 12}, {label, <<"SF8 500 kHz (12500 bit/s)">>}],
            [{value, 13}, {label, <<"SF7 500 kHz (21900 bit/s)">>}]];
        true ->
            both_datar_choices0(Region)
    end.

both_datar_choices0(Region) ->
    if
        Region == <<"EU868">>; Region == <<"CN779">>; Region == <<"EU433">>;
        Region == <<"AS923">>; Region == <<"RU868">>;
        Region == <<"CN470">>; Region == <<"KR920">>; Region == <<"IN865">> -> [
            [{value, 0}, {label, <<"SF12 125 kHz (250 bit/s)">>}],
            [{value, 1}, {label, <<"SF11 125 kHz (440 bit/s)">>}],
            [{value, 2}, {label, <<"SF10 125 kHz (980 bit/s)">>}],
            [{value, 3}, {label, <<"SF9 125 kHz (1760 bit/s)">>}],
            [{value, 4}, {label, <<"SF8 125 kHz (3125 bit/s)">>}],
            [{value, 5}, {label, <<"SF7 125 kHz (5470 bit/s)">>}]] ++
        if
            Region == <<"EU868">>; Region == <<"CN779">>; Region == <<"EU433">>;
            Region == <<"AS923">>; Region == <<"RU868">> -> [
                [{value, 6}, {label, <<"SF7 250 kHz (11000 bit/s)">>}],
                [{value, 7}, {label, <<"50 kbps (50000 bit/s)">>}]];
            true ->
                []
        end
    end.

power_choices0(Idx, Power, Min) when Idx =< Min ->
    [[{value, Idx}, {label, <<(integer_to_binary(Power))/binary, " dBm">> }] | power_choices0(Idx+1, Power-2, Min)];
power_choices0(_Idx, _Power, _Min) ->
    [].

resource_exists(Req, State) ->
    {true, Req, State}.

% end of file
