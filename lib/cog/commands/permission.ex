defmodule Cog.Commands.Permission do
  use Cog.Command.GenCommand.Base, bundle: Cog.embedded_bundle
  require Cog.Commands.Helpers, as: Helpers

  alias Cog.Commands.Permission.{Create, Delete, Grant, Info, List, Revoke}

  @description "Manage authorization permissions"

  Helpers.usage :root, """
  #{@description}

  USAGE
    permission [subcommand]

  FLAGS
    -h, --help  Display this usage info

  SUBCOMMANDS
    create     Create a new site permission
    delete     Delete an existing site permission
    grant      Grant a permission to a role
    info       Get detailed information about a specific permission
    list       List all permissions (default)
    revoke     Revoke a permission from a group

  """

  permission "manage_permissions"
  permission "manage_roles"

  # first rule is for default list scenario
  rule "when command is #{Cog.embedded_bundle}:permission must have #{Cog.embedded_bundle}:manage_permissions"

  rule "when command is #{Cog.embedded_bundle}:permission with arg[0] == create must have #{Cog.embedded_bundle}:manage_permissions"
  rule "when command is #{Cog.embedded_bundle}:permission with arg[0] == delete must have #{Cog.embedded_bundle}:manage_permissions"
  rule "when command is #{Cog.embedded_bundle}:permission with arg[0] == info must have #{Cog.embedded_bundle}:manage_permissions"
  rule "when command is #{Cog.embedded_bundle}:permission with arg[0] == list must have #{Cog.embedded_bundle}:manage_permissions"
  rule "when command is #{Cog.embedded_bundle}:permission with arg[0] == grant must have #{Cog.embedded_bundle}:manage_roles"
  rule "when command is #{Cog.embedded_bundle}:permission with arg[0] == revoke must have #{Cog.embedded_bundle}:manage_roles"

  def handle_message(req, state) do
    {subcommand, args} = Helpers.get_subcommand(req.args)

    result = case subcommand do
               "create" -> Create.create(req, args)
               "delete" -> Delete.delete(req, args)
               "grant"  -> Grant.grant(req, args)
               "info"   -> Info.info(req, args)
               "list"   -> List.list(req, args)
               "revoke" -> Revoke.revoke(req, args)
               nil ->
                 if Helpers.flag?(req.options, "help") do
                   show_usage
                 else
                   List.list(req, args)
                 end
               other ->
                 {:error, {:unknown_subcommand, other}}
             end

    case result do
      {:ok, template, data} ->
         {:reply, req.reply_to, template, data, state}
      {:ok, data} ->
        {:reply, req.reply_to, data, state}
      {:error, err} ->
        {:error, req.reply_to, error(err), state}
    end
  end

  defp error(:invalid_permission),
    do: "Only permissions in the `site` namespace can be created or deleted; please specify permission as `site:<NAME>`"
  defp error(:wrong_type),
    do: "Arguments must be strings"
  defp error(error),
    do: Helpers.error(error)

end
