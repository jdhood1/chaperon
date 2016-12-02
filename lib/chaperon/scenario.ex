defmodule Chaperon.Scenario do
  defstruct [
    module: nil,
    sessions: [],
  ]

  @type t :: %Chaperon.Scenario{
    module: atom,
    sessions: [Chaperon.Session.t]
  }

  defmacro __using__(_opts) do
    quote do
      require Chaperon.Scenario
      import  Chaperon.Scenario
      import  Chaperon.Timing
      import  Chaperon.Session

      def start_link(opts) do
        with {:ok, session} <- %Chaperon.Session{scenario: __MODULE__} |> init do
          Scenario.Task.start_link session
        end
      end
    end
  end


  alias Chaperon.Session
  alias Chaperon.Action.SpreadAsync

  @doc """
  Concurrently spreads a given action with a given rate over a given time interval
  """
  @spec cc_spread(Session.t, atom, SpreadAsync.rate, SpreadAsync.time) :: Session.t
  def cc_spread(session, action_name, rate, interval) do
    action = %SpreadAsync{
      callback: {session.scenario.name, action_name},
      rate: rate,
      interval: interval
    }
    session
    |> Session.run_action(action)
  end

  defmacro session ~> func_call do
    quote do
      unquote(session)
      |> call(fn s ->
        s
        |> unquote(func_call)
      end)
    end
  end

  def execute(scenario_mod, config) do
    # TODO: load & pass in scenario config
    scenario = %Chaperon.Scenario{module: scenario_mod}
    session = %Chaperon.Session{
      id: "test-session",
      scenario: scenario,
      config: config
    }

    {:ok, session} = session |> scenario_mod.init
    session = session
              |> scenario_mod.run
  end
end
