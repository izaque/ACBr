{******************************************************************************}
{ Projeto: Componentes ACBr                                                    }
{  Biblioteca multiplataforma de componentes Delphi para intera��o com equipa- }
{ mentos de Automa��o Comercial utilizados no Brasil                           }
{                                                                              }
{ Direitos Autorais Reservados (c) 2004 Daniel Simoes de Almeida               }
{                                                                              }
{ Colaboradores nesse arquivo: Alexandre Rocha Lima e Marcondes                }
{                                                                              }
{  Voc� pode obter a �ltima vers�o desse arquivo na pagina do  Projeto ACBr    }
{ Componentes localizado em      http://www.sourceforge.net/projects/acbr      }
{                                                                              }
{ Esse arquivo usa a classe  SynaSer   Copyright (c)2001-2003, Lukas Gebauer   }
{  Project : Ararat Synapse     (Found at URL: http://www.ararat.cz/synapse/)  }
{                                                                              }
{  Esta biblioteca � software livre; voc� pode redistribu�-la e/ou modific�-la }
{ sob os termos da Licen�a P�blica Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a vers�o 2.1 da Licen�a, ou (a seu crit�rio) }
{ qualquer vers�o posterior.                                                   }
{                                                                              }
{  Esta biblioteca � distribu�da na expectativa de que seja �til, por�m, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia impl�cita de COMERCIABILIDADE OU      }
{ ADEQUA��O A UMA FINALIDADE ESPEC�FICA. Consulte a Licen�a P�blica Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICEN�A.TXT ou LICENSE.TXT)              }
{                                                                              }
{  Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral Menor do GNU junto}
{ com esta biblioteca; se n�o, escreva para a Free Software Foundation, Inc.,  }
{ no endere�o 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Voc� tamb�m pode obter uma copia da licen�a em:                              }
{ http://www.opensource.org/licenses/lgpl-license.php                          }
{                                                                              }
{ Daniel Sim�es de Almeida  -  daniel@djsystem.com.br  -  www.djsystem.com.br  }
{              Pra�a Anita Costa, 34 - Tatu� - SP - 18270-410                  }
{                                                                              }
{******************************************************************************}

{$I ACBr.inc}

unit ACBrSMSGenerico;

interface

uses
  ACBrSMSClass, Classes, SysUtils;

type
  TACBrSMSGenerico = class(TACBrSMSClass)
  private

  public
    function EmLinha: Boolean; override;
    function IMEI: AnsiString; override;
    function Operadora: AnsiString; override;
    function NivelSinal: Double; override;
    function Fabricante: AnsiString; override;
    function ModeloModem: AnsiString; override;
    function Firmware: AnsiString; override;
    function EstadoSincronismo: TACBrSMSSincronismo; override;

    procedure EnviarSMS(const ATelefone: AnsiString;
      const AMensagem: AnsiString; var AIndice: String); override;
    procedure ListarMensagens(const AFiltro: TACBrSMSFiltro;
      const APath: AnsiString); override;

  end;

implementation

uses
  ACBrDevice, ACBrUtil, ACBrConsts;

{ TACBrSMSGenerico }

function TACBrSMSGenerico.EmLinha: Boolean;
begin
  Self.EnviarComando('AT');
  Result := fpATResult;
end;

function TACBrSMSGenerico.IMEI: AnsiString;
begin
  Self.EnviarComando('AT+CGSN');

  if Self.ATResult then
    Result := Trim(Copy(fpUltimaResposta, 1, Pos('OK', fpUltimaResposta) - 1))
  else
    Result := EmptyStr;
end;

procedure TACBrSMSGenerico.ListarMensagens(const AFiltro: TACBrSMSFiltro;
  const APath: AnsiString);
var
  cmd: AnsiString;
  Retorno: String;
  I: Integer;
begin
  case AFiltro of
    fltTudo:     cmd := 'AT+CMGL="ALL"';
    fltLidas:    cmd := 'AT+CMGL="REC READ"';
    fltNaoLidas: cmd := 'AT+CMGL="REC UNREAD"';
  end;

  Self.EnviarComando(cmd);
  if Self.ATResult then
  begin
    Retorno := EmptyStr;
    for I := 0 to Length(fpUltimaResposta) - 1 do
    begin
      if not(fpUltimaResposta[I] in [#0, #5, #$18, #$C]) then
        Retorno := Retorno + fpUltimaResposta[I];
    end;

    fpUltimaResposta := Trim(Retorno);
    WriteToTXT(APath, fpUltimaResposta, False, True);
  end;
end;

function TACBrSMSGenerico.ModeloModem: AnsiString;
begin
  Self.EnviarComando('AT+CGMM');

  if Self.ATResult then
    Result := Trim(Copy(fpUltimaResposta, 1, Pos('OK', fpUltimaResposta) - 1))
  else
    Result := EmptyStr;
end;

function TACBrSMSGenerico.Fabricante: AnsiString;
begin
  Self.EnviarComando('AT+CGMI');

  if Self.ATResult then
    Result := Trim(Copy(fpUltimaResposta, 1, Pos('OK', fpUltimaResposta) - 1))
  else
    Result := EmptyStr;
end;

function TACBrSMSGenerico.Firmware: AnsiString;
begin
  Self.EnviarComando('AT+CGMR');

  if Self.ATResult then
    Result := Trim(Copy(fpUltimaResposta, 1, Pos('OK', fpUltimaResposta) - 1))
  else
    Result := EmptyStr;
end;

function TACBrSMSGenerico.NivelSinal: Double;
var
  RetCmd: AnsiString;
begin
  Self.EnviarComando('AT+CSQ');

  if Self.ATResult then
  begin
    RetCmd := AnsiUpperCase(fpUltimaResposta);
    RetCmd := Trim(Copy(RetCmd, 1, Pos('OK', RetCmd) - 1));
    RetCmd := Trim(Copy(RetCmd, pos(':', RetCmd) + 1, Length(RetCmd)));

    Result := StrToFloatDef(String(RetCmd), 0.00);
  end
  else
    Result := 0;
end;

function TACBrSMSGenerico.Operadora: AnsiString;
begin
  Self.EnviarComando('AT+COPS?');

  if Self.ATResult then
  begin
    Result := Trim(Copy(fpUltimaResposta, 1, Pos('OK', fpUltimaResposta) - 1));
    Result := Copy(Result, Pos('"', Result) + 1, Length(Result));
    Result := Copy(Result, 1, Pos('"', Result) - 1);
  end
  else
    Result := EmptyStr;
end;

function TACBrSMSGenerico.EstadoSincronismo: TACBrSMSSincronismo;
var
  RetCmd: AnsiString;
  Retorno: Integer;
begin
  Self.EnviarComando('AT+CREG?');

  if Self.ATResult then
  begin
    RetCmd := fpUltimaResposta;
    RetCmd := Trim(Copy(RetCmd, 1, Pos('OK', RetCmd) - 1));
    RetCmd := Trim(Copy(RetCmd, pos(':', RetCmd) + 1, Length(RetCmd)));

    if RetCmd = '0,1' then
      Result := sinSincronizado
    else if RetCmd = '0,2' then
      Result := sinBucandoRede
    else
      Result := sinNaoSincronizado;
  end
  else
    Result := sinErro;
end;

procedure TACBrSMSGenerico.EnviarSMS(const ATelefone,
  AMensagem: AnsiString; var AIndice: String);
var
  Cmd: AnsiString;
  Ret: AnsiString;
begin
  // verificar se o sincard est� sincronizado **********************************
  if EstadoSincronismo <> sinSincronizado then
    raise EACBrSMSException.Create(FALHA_SINCARD_SINCRONIZADO);


  // definir o modo de envio ***************************************************
  Cmd := 'AT+CMGF=1';
  Self.EnviarComando(Cmd);
  if not Self.ATResult then
    raise EACBrSMSException.Create(FALHA_INICIALIZACAO + sLineBreak + fpUltimaResposta);


  // definir o n�mero de telefone do destinat�rio ******************************
  Cmd := 'AT+CMGS="' + ATelefone + '"';
  Self.EnviarBuffer(Cmd);
  if Pos('>', fpUltimaResposta) <= 0 then
    raise EACBrSMSException.Create(FALHA_NUMERO_TELEFONE + sLineBreak + fpUltimaResposta);


  // Enviar a mensagem *********************************************************
  Cmd := Trim(AMensagem) + CTRL_Z;
  Self.EnviarComando(Cmd);
  if not Self.ATResult then
    raise EACBrSMSException.Create(FALHA_ENVIAR_MENSAGEM + sLineBreak + fpUltimaResposta);


  // verificar se foi retornado indice da mensagem *****************************
  Ret := fpUltimaResposta;
  if Pos(':', Ret) >= 0 then
  begin
    // separar o indice da mensagem
    Ret := Trim(Copy(Ret, Pos(':', Ret) + 1, Length(Ret)));
    Ret := Trim(Copy(Ret, 1, Pos('OK', Ret) - 1));

    AIndice := IntToStr(StrToIntDef(Trim(Ret), -1));
    if AIndice = '-1' then
      raise EACBrSMSException.Create(FALHA_INDICE_MENSAGEM + sLineBreak + fpUltimaResposta);
  end
  else
    AIndice := '-1';
end;

end.
