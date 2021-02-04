CREATE OR REPLACE PACKAGE INT_CARGA_GUIAS_CPROC IS

-----------------------------------------------------------------------------------------------------------------------

  FUNCTION Parametros RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Versao RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  FUNCTION Modulo RETURN VARCHAR2;
  FUNCTION Classificacao RETURN VARCHAR2;
  FUNCTION Orientacao RETURN VARCHAR2;
  FUNCTION Executar(  PEMPRESA       VARCHAR2,
                      PESTAB         VARCHAR2,
                      PDT_INI        date,
                      PDT_FIM        date,
                      P_NM_DIRETORIO VARCHAR2,
                      P_NM_ARQUIVO   VARCHAR2 )
                     RETURN INTEGER;
END INT_CARGA_GUIAS_CPROC;
/
CREATE OR REPLACE PACKAGE BODY INT_CARGA_GUIAS_CPROC
   IS
   v_hora_ini   char(25);
   mcod_empresa          empresa.cod_empresa%TYPE;
   mcod_estab            estabelecimento.cod_estab%type;
   --
   mproc_ant  INTEGER;
   --
   -- Variaveis Carga
   carq   UTL_FILE.file_type;
   cLin    varchar2(32000);
   iLinha  number (10):=0;
   v_cont  number:=0;
   cont    number:=0;  
   tam_ini number;
   v_cont2 number:=0;
   tam_fim number;
   texto   varchar2(3000);
   --
   v_cod_empresa        varchar2(100);
   v_cod_estab          varchar2(100);
   v_dat_compete        date;
   v_ind_normal         varchar2(100);
   v_dat_vencto         date;
   v_cod_receita        varchar2(100);
   v_vlr_receita        varchar2(100);
   V_cod_clas_vcto      varchar2(100);
   v_ind_origem         varchar2(100);
   v_num_acordo         varchar2(100);
   --
  
  FUNCTION Parametros RETURN VARCHAR2 IS
        pstr       VARCHAR2(5000);
      BEGIN
        -- Titulo..........: Caption a ser mostrado na tela
        -- Tipo da Variavel: Conforme definido no Oracle
        -- Tipo de Controle: Textbox, Listbox, Combobox, Radiobutton ou Checkbox
        -- Mandatorio......: S ou N
        -- Dafault.........: Valor Default para o Campo
        -- Mascara.........: dd/mm/yyyy
        -- Valores.........: Comando SQL para a lista (Codigo, Descric?o)

        mcod_empresa := lib_parametros.recuperar('empresa');
        mcod_estab   := nvl(lib_parametros.recuperar('estabelecimento'), '');

        -- lista de argumentos:

         -- 1) empresa.
         lib_proc.add_param(pstr,
                        'Empresa',
                        'varchar2',
                        'combobox',
                        's',
                        null,
                        null,
                        'select a.cod_empresa, a.cod_empresa||'' - ''||a.razao_social from empresa a where a.cod_empresa = ''' ||
                        mcod_empresa || ''' order by a.cod_empresa');


        -- 2) Estabelecimento.
        lib_proc.add_param(pstr,
                        'Estabelecimento',
                        'Varchar2',
                        'Combobox',
                        'S',
                        NULL,
                        NULL,
/*                       'SELECT a.cod_estab, a.cod_estab||'' - ''||a.razao_social||'' - ''||b.cod_estado FROM estabelecimento a, estado b WHERE a.cod_empresa = ''' ||
                        mcod_empresa || ''' and a.ident_estado=b.ident_estado ORDER BY a.cod_estab');*/
                        'SELECT a.cod_estab, a.cod_estab||'' - ''||a.razao_social||'' - ''||b.cod_estado FROM estabelecimento a, estado b WHERE a.cod_empresa = ''' ||
                        mcod_empresa || ''' and a.ident_estado = b.ident_estado and b.cod_estado = ''SC'' UNION SELECT ''9999'',''9999-Todos'' FROM DUAL ORDER BY 1' );                         
                        
--                        'AND   e.cod_empresa = ''' || Mcod_Empresa || ''' UNION SELECT ''0'', ''* Todos *'' FROM dual ',
                        

        -- 3) Data Inicial.
        lib_proc.add_param(pstr,
                        'Periodo Inicial',
                        'date',
                        'Textbox',
                        'S',
                         NULL,
                        'dd/mm/yyyy');


        -- 4) Data Final.
        lib_proc.add_param(pstr,
                        'Periodo Final',
                        'date',
                        'Textbox',
                        'S',
                        NULL,
                        'dd/mm/yyyy');

        -- 5) Diretório.
        lib_proc.add_param(pstr,
                        'Diretório',
                        'Varchar2',
                        'Textbox',
                        'N',
                        NULL,
                        NULL);

        -- 6 ) Nome do arquivo.
        lib_proc.add_param(pstr,
                        'Nome do arquivo (.TXT)',
                        'Varchar2',
                        'Textbox',
                        'N',
                        NULL,
                        NULL);

        RETURN pstr;
      END;

     FUNCTION Gera_Linha_Final_Arquivo RETURN VARCHAR2 IS
     BEGIN
      RETURN 'S';
     END;


      FUNCTION Nome RETURN VARCHAR2 IS
      BEGIN
        -- Nome da janela
        RETURN 'INT_CARGA_GUIAS_CPROC';
      END;

      FUNCTION Tipo RETURN VARCHAR2 IS
      BEGIN
        RETURN 'RELATORIOS LIVROS FISCAIS';
      END;

      FUNCTION Versao RETURN VARCHAR2 IS
      BEGIN
        RETURN ' 1.0 ';
      END;

      FUNCTION Descricao RETURN VARCHAR2 IS
      BEGIN
        RETURN 'Carga Guia';
      END;

      FUNCTION Modulo RETURN VARCHAR2 IS
      BEGIN
        RETURN 'Processos Customizados';
      END;

      FUNCTION Classificacao RETURN VARCHAR2 IS
      BEGIN
        RETURN 'REL MSAF';
      END;

      FUNCTION Orientacao RETURN VARCHAR2 IS
      BEGIN
        -- Orientacao do Papel
        RETURN ' LANDSCAPE ';
      END;

      FUNCTION Executar( PEMPRESA       VARCHAR2,
                         PESTAB         VARCHAR2,
                         PDT_INI        date,
                         PDT_FIM        date,
                         P_NM_DIRETORIO VARCHAR2,
                         P_NM_ARQUIVO   VARCHAR2
                          )
            RETURN INTEGER IS

            musuario            VARCHAR2(20);
            mproc_id            INTEGER;
            --
            BEGIN
              v_hora_ini := to_char(sysdate,'dd/mm/yyyy hh:mi:ss');
              mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
              musuario     := LIB_PARAMETROS.RECUPERAR('USUARIO');
              -- Crio um novo processo
              mproc_id := lib_proc.new('INT_CARGA_GUIAS_CPROC', 48, 155);
              --Cria o processo
              SAF_INI_PROCESSO('CARGA_D',mcod_empresa,NULL,PDT_INI,PDT_FIM,musuario,mproc_ant);
              --
              lib_proc.add_log(LPAD('-',145,'-'),0);
              lib_proc.add_log('Log de Processo ', 0);
              lib_proc.add_log('EMPRESA: ' || PEMPRESA, 0);
              lib_proc.add_log('ESTAB: ' || REPLACE(PESTAB,'9999','TODOS') , 0);
              lib_proc.add_log('PERIODO ' || TO_CHAR(PDT_INI, 'DD/MM/YYYY') || ' A ' || TO_CHAR(PDT_FIM, 'DD/MM/YYYY'), 0);
              lib_proc.add_log(LPAD('-',145,'-'),0);
              lib_proc.add_log(' ',0);

              IF mcod_empresa IS NULL THEN
                lib_proc.Add_Log('Codigo da Empresa deve ser informado como parametro Global.',
                            0);
                lib_proc.CLOSE;
                RETURN mproc_id;
              END IF;

              IF PDT_INI IS NULL THEN
                lib_proc.Add_Log('O Periodo Inicial deve ser informado.',
                            0);
                lib_proc.CLOSE;
                RETURN mproc_id;
              END IF;

              IF PDT_FIM IS NULL THEN
                lib_proc.Add_Log('O Periodo Final deve ser informado.',
                            0);
                lib_proc.CLOSE;
                RETURN mproc_id;
              END IF;

              IF PDT_FIM < PDT_INI THEN
                lib_proc.Add_Log('Data Final Menor do que Data Inicial.',
                            0);
                lib_proc.CLOSE;
                RETURN mproc_id;
              END IF;

              IF to_char(PDT_FIM,'MM') <> TO_CHAR(PDT_INI,'MM') THEN
                lib_proc.Add_Log('O Mes Inicial e Mes final devem ser iguais.',
                            0);
                lib_proc.CLOSE;
                RETURN mproc_id;
              END IF;

              IF P_NM_DIRETORIO IS NUlL THEN
                lib_proc.Add_Log('Favor Informar o Diretorio onde esta o Arquivo TXT:',
                            0);
                lib_proc.CLOSE;
                RETURN mproc_id;
              END IF;

              IF P_NM_ARQUIVO IS NULl THEN
                lib_proc.Add_Log('Favor Informar o Nome do Arquivo TXT:',
                            0);
                lib_proc.CLOSE;
                RETURN mproc_id;
              END IF;


       --                 <<<<<<<<<< INSERE A CHAMADA DA CARGA >>>>>>
       BEGIN
          --
          --  Geração Carga Tabela SAP
          --
          BEGIN
             -- limpeza das tabelas - Nova Carga
             Begin
                delete from EST_SC_GUIA_RECOL GUI
                 where gui.cod_empresa = PEMPRESA
                   and gui.cod_estab   = REPLACE(PESTAB,'9999',gui.cod_estab) 
                   and gui.dat_competencia between PDT_INI AND PDT_FIM;
             Exception
                when others then
                     null;  -- Tratamento de LOG
             End;
             --
             -- tratamento de abertura do arquivo texto
             
             Begin
                carq := UTL_FILE.fopen(p_nm_diretorio,p_nm_arquivo,'r');
             exception
               when utl_file.write_error then
                 raise_application_error(-20011,'Erro de Escrita. ');

               when utl_file.invalid_path then
                 raise_application_error(-20012,'Diretório inválido. ');

               when utl_file.invalid_mode then
                 raise_application_error(-20013,'Modo inválido. ');

               when utl_file.invalid_operation then
                 raise_application_error(-20014,'Operação inválida. ');

               when others then

                 raise_application_error(-20015,'Arquivo: '||ltrim(trim(p_nm_diretorio))||p_nm_arquivo||
                                                 ' invalido ou sem permissao de uso.');

             end;
             --
             --
             iLinha      :=0;
             v_cont      :=0;
             v_cont2     :=0;
             --
             LOOP
               --
               Begin
                 --               
                 Begin
                    Utl_File.get_line(carq,clin);
                    iLinha := Ilinha +1;
                 exception
                      when no_data_found then                 
                           Exit;
                      when others then
                           raise_application_error(-20999,'Arquivo: '||p_nm_diretorio||p_nm_arquivo||' Erro Get Line');
                       exit;
                 end;
                 --
                 tam_ini    := 1;
                 tam_fim    := length(clin);
                 texto      :='';
                 --                 
              Begin
                 --
                 cont := 0;
                 --
                 for i in tam_ini .. tam_fim 
                 
                   LOOP
                     --
                     Begin
                     --
                     if   substr(clin,i,1) = chr(9) or i=tam_fim then
                          --
                          cont:=cont+1;
                          --
                          if cont             = 1 then    -- Empresa negocio
                             v_cod_empresa   :=texto;
                          elsif cont          = 2 then    -- Local negocio
                             v_cod_estab     :=texto;
                          elsif cont          = 3 then    -- Data Competencia
                             v_dat_compete   := TO_DATE(texto,'DD/MM/YYYY');
                          elsif cont         = 4 then    -- Indicador Normalidade
                            v_ind_normal     :=texto;
                          elsif cont         = 5 then    -- Data de vencimento
                            v_dat_vencto     :=TO_DATE(texto,'DD/MM/YYYY');
                          elsif cont         = 6 then    -- Codigo da Receita
                            v_cod_receita    :=texto;
                          elsif cont         = 7 then    -- Valor 
                             v_vlr_receita :=texto;
                          elsif cont         = 8 then    -- Codigo Classificação Vcto
                             V_cod_clas_vcto :=texto;
                          elsif cont         = 9 then    -- Indicador de Origem
                             v_ind_origem    :=texto;
                          elsif cont         = 10 then    -- Numero do Acordo
                            v_num_acordo     :=texto;
                          end if;
                    --
                          texto:='';
                    --
                    else
                          --
                          texto:= texto || substr(clin,i,1);
                          --
                    end if;
                    
                    End;
                    
                 End Loop;
                 
                 IF  (v_cod_empresa  = PEMPRESA  and
                     (v_cod_estab    = PESTAB or PESTAB = '9999' )) THEN 
                     -- insere os registros nas tabelas
                     IF  v_dat_compete >= PDT_INI AND
                         v_dat_compete <= PDT_FIM then
                         --
                         Begin
                           --
                           insert into EST_SC_GUIA_RECOL
                                         values (  v_cod_empresa,             --  1
                                                   v_cod_estab,               --  2
                                                   v_dat_compete,             --  3
                                                   v_ind_normal,              -- 4
                                                   v_dat_vencto,              -- 5
                                                   v_cod_receita,             -- 6
                                                   to_number(replace(nvl(v_vlr_receita,0),',','.')),  --7
                                                   V_cod_clas_vcto,           -- 8
                                                   v_ind_origem,              -- 9
                                                   v_num_acordo               -- 10
                                                    );
                           --                             
                           v_cont2 := v_cont2 + 1;
                           --                                                    
                                                    
                         Exception
                           when others then
                                lib_proc.add_log('ocorreu erro na gravação :'||SUBSTR(SQLERRM, 1 , 100), 0);
                         End;
                         --
                         v_cont := v_cont + 1;

                     END IF;

                  End If;

             --
           end;
           --
           END;
           --
           END LOOP;
               
       commit;
       
       END;
       
       lib_proc.add_log('Total Registros LIDOS     : '||v_cont, 0);
       lib_proc.add_log('Total Registros INSERIDOS : '||v_cont2, 0);
       --fecho o processo
       lib_proc.CLOSE;
       RETURN mproc_id;             
       --
       END;
      --
    Exception
        when others then
             lib_proc.Add_Log('Erro - Verificar Geral Não identificado - Msg Banco: ' ||SQLERRM,0);
             lib_proc.CLOSE;
             RETURN mproc_id;

  END;

END INT_CARGA_GUIAS_CPROC;
/
