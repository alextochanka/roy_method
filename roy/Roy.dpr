program Roy;

uses
  Vcl.Forms,
  PartialSwarmInt in 'PartialSwarmInt.pas' {PartialSwarm},
  PSO_Engine in 'PSO_Engine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPartialSwarm, PartialSwarm);
  Application.Run;
end.
