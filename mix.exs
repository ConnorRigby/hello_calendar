defmodule HelloCalendar.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  Mix.shell.info([:green, """
  Mix environment
    MIX_TARGET:   #{@target}
    MIX_ENV:      #{Mix.env}
  """, :reset])

  def project do
    [app: :hello_calendar,
     version: "0.1.0",
     elixir: "~> 1.4",
     target: @target,
     compilers: [:elixir_make] ++ Mix.compilers(),
     make_clean: ["clean"],
     archives: [nerves_bootstrap: "~> 0.6"],
     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",
     lockfile: "mix.lock.#{@target}",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(@target),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application, do: application(@target)

  # Specify target specific application configurations
  # It is common that the application start function will start and supervise
  # applications which could cause the host to fail. Because of this, we only
  # invoke HelloCalendar.start/2 when running on a target.
  def application("host") do
    [extra_applications: [:logger]]
  end
  def application(_target) do
    [mod: {HelloCalendar.Application, []},
     extra_applications: [:logger]]
  end

  def deps do
    [
      {:nerves, "~> 0.7", runtime: false},
      {:elixir_make, "~> 0.4.0"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  def deps("host"), do: []
  def deps(target) do
    [
      {:bootloader, "~> 0.1"},
      {:nerves_runtime, "~> 0.4"}
    ] ++ system(target)
  end

  def system("rpi"), do: [{:nerves_system_rpi, ">= 0.0.0", runtime: false}]
  def system("rpi0"), do: [{:nerves_system_rpi0, ">= 0.0.0", runtime: false}]
  def system("rpi2"), do: [{:nerves_system_rpi2, ">= 0.0.0", runtime: false}]
  def system("rpi3"), do: [{:nerves_system_rpi3, ">= 0.0.0", runtime: false}]
  def system("bbb"), do: [{:nerves_system_bbb, ">= 0.0.0", runtime: false}]
  def system("ev3"), do: [{:nerves_system_ev3, ">= 0.0.0", runtime: false}]
  def system("qemu_arm"), do: [{:nerves_system_qemu_arm, ">= 0.0.0", runtime: false}]
  def system("x86_64"), do: [{:nerves_system_x86_64, ">= 0.0.0", runtime: false}]
  def system(target), do: Mix.raise "Unknown MIX_TARGET: #{target}"

  # We do not invoke the Nerves Env when running on the Host
  def aliases("host"), do: []
  def aliases(_target) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end
