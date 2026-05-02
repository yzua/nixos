# oh-my-pi configuration: model roles and defaults.
_:

let
  models = import ../../helpers/_models.nix;
in
{
  programs.aiAgents.omp = {
    enable = true;
    defaultModel = models.omp-default;
    planModel = models.omp-plan;
    smolModel = models.omp-smol;
  };
}
