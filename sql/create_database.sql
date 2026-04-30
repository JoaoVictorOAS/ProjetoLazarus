-- ============================================================
-- Ferramenta de Gestão Ágil com Métricas de Software
-- Banco: PostgreSQL  |  Lazarus + pqconnection (SQLdb)
-- ============================================================

-- ------------------------------------------------------------
-- membros
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS membros (
  id        SERIAL PRIMARY KEY,
  nome      TEXT    NOT NULL,
  papel     TEXT    NOT NULL CHECK(papel IN ('dev','qa','po','sm','designer','outro')),
  email     TEXT    UNIQUE,
  ativo     BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- projetos
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS projetos (
  id          SERIAL PRIMARY KEY,
  nome        TEXT    NOT NULL,
  descricao   TEXT,
  status      TEXT    NOT NULL DEFAULT 'ativo' CHECK(status IN ('ativo','pausado','encerrado')),
  data_inicio DATE    NOT NULL DEFAULT CURRENT_DATE,
  data_fim    DATE,
  criado_em   TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- projeto_membros  (n:n)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS projeto_membros (
  projeto_id INTEGER NOT NULL REFERENCES projetos(id) ON DELETE CASCADE,
  membro_id  INTEGER NOT NULL REFERENCES membros(id)  ON DELETE CASCADE,
  PRIMARY KEY (projeto_id, membro_id)
);

-- ------------------------------------------------------------
-- sprints
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sprints (
  id             SERIAL PRIMARY KEY,
  projeto_id     INTEGER NOT NULL REFERENCES projetos(id) ON DELETE CASCADE,
  numero         INTEGER NOT NULL,
  goal           TEXT,
  capacidade_pts INTEGER NOT NULL DEFAULT 0,
  status         TEXT    NOT NULL DEFAULT 'planejada' CHECK(status IN ('planejada','ativa','encerrada')),
  data_inicio    DATE,
  data_fim       DATE,
  UNIQUE(projeto_id, numero)
);

-- ------------------------------------------------------------
-- tarefas
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tarefas (
  id            SERIAL PRIMARY KEY,
  sprint_id     INTEGER REFERENCES sprints(id) ON DELETE SET NULL,
  membro_id     INTEGER REFERENCES membros(id) ON DELETE SET NULL,
  titulo        TEXT    NOT NULL,
  descricao     TEXT,
  tipo          TEXT    NOT NULL DEFAULT 'story' CHECK(tipo IN ('story','bug','task','spike')),
  status        TEXT    NOT NULL DEFAULT 'backlog' CHECK(status IN ('backlog','todo','doing','review','done')),
  pontos        INTEGER NOT NULL DEFAULT 0,
  prioridade    INTEGER NOT NULL DEFAULT 2 CHECK(prioridade BETWEEN 1 AND 5),
  criado_em     TIMESTAMP NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- horas_tecnicas
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS horas_tecnicas (
  id         SERIAL PRIMARY KEY,
  tarefa_id  INTEGER   NOT NULL REFERENCES tarefas(id) ON DELETE CASCADE,
  membro_id  INTEGER   NOT NULL REFERENCES membros(id) ON DELETE CASCADE,
  tipo       TEXT      NOT NULL CHECK(tipo IN ('desenvolvimento','code_review','testes','reuniao','documentacao','devops','suporte','arquitetura')),
  inicio     TIMESTAMP NOT NULL,
  fim        TIMESTAMP,
  total_min  INTEGER   GENERATED ALWAYS AS (
               CASE WHEN fim IS NOT NULL
               THEN EXTRACT(EPOCH FROM (fim - inicio))::INTEGER / 60
               ELSE NULL END
             ) STORED,
  obs        TEXT,
  criado_em  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- views
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_horas_por_tarefa AS
SELECT
  t.id                                          AS tarefa_id,
  t.titulo,
  t.pontos,
  SUM(h.total_min)                              AS total_min,
  ROUND(SUM(h.total_min) / 60.0, 2)            AS total_horas,
  COUNT(DISTINCT h.membro_id)                   AS membros_envolvidos
FROM tarefas t
LEFT JOIN horas_tecnicas h ON h.tarefa_id = t.id
GROUP BY t.id, t.titulo, t.pontos;

CREATE OR REPLACE VIEW v_horas_por_sprint_tipo AS
SELECT
  s.id                                          AS sprint_id,
  s.numero,
  h.tipo,
  COUNT(*)                                      AS registros,
  SUM(h.total_min)                              AS total_min,
  ROUND(SUM(h.total_min) / 60.0, 2)            AS total_horas
FROM sprints s
JOIN tarefas t          ON t.sprint_id  = s.id
JOIN horas_tecnicas h   ON h.tarefa_id  = t.id
GROUP BY s.id, s.numero, h.tipo;

CREATE OR REPLACE VIEW v_velocity AS
SELECT
  s.id                                          AS sprint_id,
  s.numero,
  s.projeto_id,
  s.capacidade_pts,
  COALESCE(SUM(CASE WHEN t.status = 'done' THEN t.pontos ELSE 0 END), 0) AS pontos_entregues
FROM sprints s
LEFT JOIN tarefas t ON t.sprint_id = s.id
GROUP BY s.id, s.numero, s.projeto_id, s.capacidade_pts;

-- ------------------------------------------------------------
-- seed
-- ------------------------------------------------------------
INSERT INTO membros (nome, papel, email) VALUES
  ('João Victor', 'dev',  'joao@projeto.local'),
  ('Maria Silva', 'qa',   'maria@projeto.local'),
  ('Carlos Souza','po',   'carlos@projeto.local');

INSERT INTO projetos (nome, descricao) VALUES
  ('AgileLazarus', 'Ferramenta de gestão ágil com métricas – projeto escolar UFR');

INSERT INTO projeto_membros VALUES (1,1),(1,2),(1,3);

INSERT INTO sprints (projeto_id, numero, goal, capacidade_pts, status, data_inicio, data_fim) VALUES
  (1, 1, 'Setup inicial e módulo de projetos', 20, 'ativa', CURRENT_DATE, CURRENT_DATE + INTERVAL '14 days');

INSERT INTO tarefas (sprint_id, membro_id, titulo, tipo, status, pontos) VALUES
  (1, 1, 'Criar banco de dados PostgreSQL',  'task',  'done',  3),
  (1, 1, 'Tela de cadastro de projetos',     'story', 'doing', 5),
  (1, 2, 'Testes de cadastro de membros',    'task',  'todo',  2),
  (1, 3, 'Definir critérios de aceitação',   'story', 'todo',  3);

INSERT INTO horas_tecnicas (tarefa_id, membro_id, tipo, inicio, fim) VALUES
  (1, 1, 'desenvolvimento', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour'),
  (1, 1, 'testes',          NOW() - INTERVAL '1 hour',  NOW() - INTERVAL '30 minutes');
