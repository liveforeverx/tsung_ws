-module(ts_config_websocket).

-export([parse_config/2]).

-include("ts_profile.hrl").
-include("ts_websocket.hrl").
-include("ts_config.hrl").

-include("xmerl.hrl").


% parse dynamic variables
parse_config(Element = #xmlElement{name=dyn_variable}, Conf = #config{}) ->
    ts_config:parse(Element,Conf);
% parse websocket tags
parse_config(Element = #xmlElement{name=websocket},
             Config=#config{curid= Id, session_tab = Tab,
                            match = MatchRegExp, dynvar = DynVar,
                            subst = SubstFlag, sessions = [CurS | _]}) ->
    Type = ts_config:getAttr(atom, Element#xmlElement.attributes, type),
    % send messages can be no_ack, the rest is always ack = parse
    Ack = case Type of
	      send ->
		  ts_config:getAttr(atom, Element#xmlElement.attributes, ack, parse);
	      _ ->
		  parse
	  end,
    Url = ts_config:getAttr(string, Element#xmlElement.attributes, url, "/"),
    % connect message can have a origin attribute
    Origin = ts_config:getAttr(string, Element#xmlElement.attributes,
			       origin, undefined),
    Data = list_to_binary(ts_config:getText(Element#xmlElement.content)),
    Request = #websocket_request{type = Type, url = Url,
				 origin = Origin, data = Data},
    Msg = #ts_request{ack = Ack,
		      endpage = true,
		      dynvar_specs = DynVar,
		      subst = SubstFlag,
		      match = MatchRegExp,
		      param = Request},

    ts_config:mark_prev_req(Id-1, Tab, CurS),
    ets:insert(Tab,{{CurS#session.id, Id}, Msg }),
    lists:foldl(fun(A,B) -> ts_config:parse(A,B) end,
		Config#config{dynvar = []},
		Element#xmlElement.content);
% parse other tags
parse_config(Element=#xmlElement{}, Conf=#config{}) ->
    ts_config:parse(Element,Conf);
% parse non-XML elements
parse_config(_, Conf=#config{}) ->
    Conf.
