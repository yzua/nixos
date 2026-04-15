# Sets hostname and stateVersion from flake arguments.
# Always active — every host needs these set.

{
  hostname,
  stateVersion,
  ...
}:

{
  networking.hostName = hostname;
  system.stateVersion = stateVersion;
}
