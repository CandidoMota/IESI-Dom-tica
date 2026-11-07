Guião de Criação de Tabelas
-- Tabelas Independentes e Lógicas
CREATE TABLE Divisao (
    nome_divisao VARCHAR(50) PRIMARY KEY,
    detalhes TEXT
);

CREATE TABLE Utilizador (
    id_utilizador SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL
);

CREATE TABLE Plano_Dia (
    id_plano SERIAL PRIMARY KEY,
    nome_plano VARCHAR(100) NOT NULL,
    horario TIME,
    modo_operacao VARCHAR(50),
    estado_plano BOOLEAN DEFAULT false
);

CREATE TABLE Modo (
    id_modo SERIAL PRIMARY KEY,
    nome_modo VARCHAR(50) NOT NULL,
    estado_modo BOOLEAN DEFAULT false
);

-- Tabela Mãe (Superclasse)
CREATE TABLE Dispositivos (
    referencia VARCHAR(50) PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL,
    estado BOOLEAN DEFAULT false,
    estado_energia BOOLEAN DEFAULT true,
    estado_rede BOOLEAN DEFAULT true,
    ficheiros_diagnostico TEXT,
    data_proxima_manutencao DATE,
    nome_divisao VARCHAR(50) REFERENCES Divisao(nome_divisao)
);

-- Tabelas Filhas (Herdam de Dispositivos)
CREATE TABLE Portas (
    id_portas SERIAL,
    id_registro VARCHAR(50),
    estado_tranca BOOLEAN,
    dados_iris TEXT,
    leitura_atual_iris TEXT,
    sinal_sonoro BOOLEAN,
    id_camara VARCHAR(50),
    estado_campainha BOOLEAN,
    stream_video_url TEXT,
    data_hora TIMESTAMP,
    metodo_autenticacao VARCHAR(50)
) INHERITS (Dispositivos);

CREATE TABLE Lampadas (
    id_lampada SERIAL
) INHERITS (Dispositivos);

CREATE TABLE Maquina_Limpar_Roupa (
    id_maquina SERIAL,
    tem_roupa BOOLEAN,
    fase_ciclo VARCHAR(50)
) INHERITS (Dispositivos);

CREATE TABLE Aspirador_Robo (
    id_aspirador SERIAL,
    lixo_cheio BOOLEAN,
    agua_vazia BOOLEAN,
    localizacao_atual VARCHAR(100)
) INHERITS (Dispositivos);

CREATE TABLE Climatizacao (
    id_climatizacao SERIAL,
    temperatura_atual DECIMAL(5,2),
    temperatura_alvo DECIMAL(5,2)
) INHERITS (Dispositivos);

CREATE TABLE Maquina_Lavar_Loica (
    id_maquina_loica SERIAL,
    tem_loica BOOLEAN,
    fase_ciclo VARCHAR(50)
) INHERITS (Dispositivos);

CREATE TABLE Persianas (
    id_persiana SERIAL,
    estado_abertura INTEGER 
) INHERITS (Dispositivos);

-- Tabelas de Ligação (Resolve a relação N:M)
CREATE TABLE Dispositivo_Plano (
    referencia_dispositivo VARCHAR(50) REFERENCES Dispositivos(referencia),
    id_plano INTEGER REFERENCES Plano_Dia(id_plano),
    PRIMARY KEY (referencia_dispositivo, id_plano)
);

Guião de Inserção de Dados
  INSERT INTO Divisao (nome_divisao, detalhes) VALUES 
('Sala de Estar', 'Zona de lazer principal no rés-do-chão'),
('Cozinha', 'Equipada com eletrodomésticos inteligentes'),
('Quarto Principal', 'Piso superior com controlo de climatização'),
('Hall de Entrada', 'Acesso principal à habitação');

INSERT INTO Utilizador (nome, password) VALUES 
('Eng. Candido Mota', 'senha_super_segura_2026'),
('Administrador Sistema', 'admin1234');

INSERT INTO Plano_Dia (nome_plano, horario, modo_operacao, estado_plano) VALUES 
('Bom Dia', '07:30:00', 'Automático', true),
('Modo Noturno', '23:00:00', 'Silencioso', true),
('Sair de Casa', '08:30:00', 'Ecológico', false);

INSERT INTO Modo (nome_modo, estado_modo) VALUES 
('Poupanca de Energia', true),
('Segurança Maxima', true);

INSERT INTO Lampadas (referencia, tipo, estado, nome_divisao) VALUES 
('LAMP-SAL-01', 'Luz LED', true, 'Sala de Estar'),
('LAMP-QUA-01', 'Luz RGB', false, 'Quarto Principal');

INSERT INTO Aspirador_Robo (referencia, tipo, nome_divisao, lixo_cheio, agua_vazia, localizacao_atual) VALUES 
('ROBO-ASP-X9', 'Limpeza', 'Cozinha', false, true, 'Base de Carregamento');

INSERT INTO Climatizacao (referencia, tipo, estado, nome_divisao, temperatura_atual, temperatura_alvo) VALUES 
('AC-QUA-01', 'Ar Condicionado', true, 'Quarto Principal', 22.5, 21.0);

INSERT INTO Portas (referencia, tipo, nome_divisao, estado_tranca, metodo_autenticacao, id_registro, data_hora) VALUES 
('PORTA-ENT-01', 'Segurança', 'Hall de Entrada', true, 'Biometria de Íris', 'REG-105', '2026-11-07 08:15:00');

INSERT INTO Dispositivo_Plano (referencia_dispositivo, id_plano) VALUES 
('LAMP-SAL-01', 2),
('AC-QUA-01', 2),
('ROBO-ASP-X9', 3);

CREATE TABLE Dispositivo_Modo (
    referencia_dispositivo VARCHAR(50) REFERENCES Dispositivos(referencia),
    id_modo INTEGER REFERENCES Modo(id_modo),
    PRIMARY KEY (referencia_dispositivo, id_modo)
);


Guião de Stored Procedures
-- Função para ver os aparelhos num determinado quarto
CREATE OR REPLACE FUNCTION ConsultarDispositivosDivisao(p_divisao VARCHAR)
RETURNS TABLE (
    ref VARCHAR, 
    tipo_equipamento VARCHAR, 
    estado_atual BOOLEAN, 
    energia_ligada BOOLEAN
) AS $$
BEGIN
    RETURN QUERY 
    SELECT d.referencia, d.tipo, d.estado, d.estado_energia
    FROM Dispositivos d
    WHERE d.nome_divisao = p_divisao;
END;
$$ LANGUAGE plpgsql;

-- Função de emergência para cortar energia a um aparelho
CREATE OR REPLACE PROCEDURE CortarEnergiaDispositivo(p_referencia VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Dispositivos
    SET estado_energia = false, estado = false
    WHERE referencia = p_referencia;
    
    COMMIT;
END;
$$;

-- Função para saber que aparelhos são afetados por um plano (ex: Modo Noturno)
CREATE OR REPLACE FUNCTION DispositivosNoPlano(p_nome_plano VARCHAR)
RETURNS TABLE (
    plano VARCHAR,
    ref_dispositivo VARCHAR,
    localizacao VARCHAR
) AS $$
BEGIN
    RETURN QUERY 
    SELECT p.nome_plano, dp.referencia_dispositivo, d.nome_divisao
    FROM Plano_Dia p
    JOIN Dispositivo_Plano dp ON p.id_plano = dp.id_plano
    JOIN Dispositivos d ON dp.referencia_dispositivo = d.referencia
    WHERE p.nome_plano = p_nome_plano;
END;
$$ LANGUAGE plpgsql;
