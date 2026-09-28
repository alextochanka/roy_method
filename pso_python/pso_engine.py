# -*- coding: utf-8 -*-
"""
Движок роя частиц (PSO) — перенос PSO_Engine.pas на Python.

Поддерживает два режима работы:
  - "classic" — обычный PSO (с опциональным адаптивным инерционным весом
    и штрафной функцией за выход из границ);
  - "hybrid"  — тот же PSO плюс механизм мутаций: если лучшее решение не
    улучшается MaxIterWithoutImprovement итераций подряд, худшая половина
    роя мутируется (сначала — локально вокруг глобального лучшего решения,
    затем — случайным переинициализированием), чтобы выбраться из
    локального минимума.

Оба режима реализованы в одном классе PSOEngine — режим переключается
параметром use_mutations, как и в исходной Delphi-программе
(USE_ADAPTIVE_WEIGHT / USE_MUTATIONS / USE_PENALTY).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Optional

import numpy as np

MUTATION_AMT = 3
MUTATION_LOCAL_RADIUS = 0.5


@dataclass
class PSOParams:
    dimension: int
    swarm_size: int = 30
    max_iter: int = 200
    self_confidence: float = 1.5          # c1
    social_confidence: float = 1.5        # c2
    max_velocity: float = 4.0
    search_range: float = 10.0
    inertia_weight: float = 0.7
    inertia_start: float = 0.9
    inertia_end: float = 0.4
    use_adaptive_weight: bool = True
    use_mutations: bool = False           # False = "classic", True = "hybrid"
    use_penalty: bool = False
    max_iter_without_improvement: int = 20
    penalty_ratio: float = 100.0
    min_values: Optional[np.ndarray] = None
    max_values: Optional[np.ndarray] = None


@dataclass
class PSOResult:
    best_position: np.ndarray
    best_fitness: float
    history: np.ndarray            # сходимость: значение на каждой итерации
    mutations_applied: int = 0


class PSOEngine:
    """Один запуск PSO/гибридного PSO для заданной целевой функции."""

    def __init__(self, fitness_fn: Callable[[np.ndarray], float], params: PSOParams,
                 rng: Optional[np.random.Generator] = None):
        self.fitness_fn = fitness_fn
        self.p = params
        self.rng = rng or np.random.default_rng()

        d = self.p.dimension
        self.position = np.zeros((0, d))
        self.velocity = np.zeros((0, d))
        self.best_position = np.zeros((0, d))
        self.best_fitness = np.zeros(0)

        self.global_best_position = np.zeros(d)
        self.global_best_fitness = np.inf

    # ------------------------------------------------------------------
    def _calculate_penalty(self, position: np.ndarray) -> float:
        p = self.p
        if p.min_values is None or p.max_values is None:
            return 0.0
        below = np.maximum(p.min_values - position, 0.0)
        above = np.maximum(position - p.max_values, 0.0)
        return float(p.penalty_ratio * (np.sum(below) + np.sum(above)))

    def _initialize_swarm(self):
        p = self.p
        if p.dimension <= 0:
            raise ValueError("Размерность должна быть больше 0")

        low, high = -p.search_range, p.search_range
        self.position = self.rng.uniform(low, high, size=(p.swarm_size, p.dimension))
        self.velocity = self.rng.uniform(-p.max_velocity, p.max_velocity,
                                          size=(p.swarm_size, p.dimension))
        self.best_position = self.position.copy()
        self.best_fitness = np.array([self.fitness_fn(self.position[i])
                                       for i in range(p.swarm_size)])

    def _find_global_best(self):
        idx = int(np.argmin(self.best_fitness))
        self.global_best_fitness = float(self.best_fitness[idx])
        self.global_best_position = self.best_position[idx].copy()

    def _update_particle(self, i: int, weight: float):
        p = self.p
        r1, r2 = self.rng.random(), self.rng.random()

        new_v = (weight * self.velocity[i]
                 + p.self_confidence * r1 * (self.best_position[i] - self.position[i])
                 + p.social_confidence * r2 * (self.global_best_position - self.position[i]))
        new_v = np.clip(new_v, -p.max_velocity, p.max_velocity)
        self.velocity[i] = new_v
        self.position[i] = self.position[i] + new_v

        if not p.use_penalty:
            self.position[i] = np.clip(self.position[i], -p.search_range, p.search_range)
            penalty = 0.0
        else:
            penalty = self._calculate_penalty(self.position[i])

        raw_fitness = self.fitness_fn(self.position[i])
        total_fitness = raw_fitness + penalty

        if total_fitness < self.best_fitness[i]:
            self.best_fitness[i] = total_fitness
            self.best_position[i] = self.position[i].copy()

        if penalty == 0 and total_fitness < self.global_best_fitness:
            self.global_best_fitness = total_fitness
            self.global_best_position = self.position[i].copy()

    def _apply_mutation(self, mutation_count: int):
        p = self.p
        order = np.argsort(self.best_fitness)
        worst_half = order[p.swarm_size // 2:]

        for idx in worst_half:
            if mutation_count == 0:
                self.position[idx] = (self.global_best_position
                                       + (self.rng.random(p.dimension) - 0.5)
                                       * p.search_range * MUTATION_LOCAL_RADIUS)
            else:
                self.position[idx] = self.rng.uniform(-p.search_range, p.search_range, p.dimension)

            self.position[idx] = np.clip(self.position[idx], -p.search_range, p.search_range)
            self.velocity[idx] = 0.0
            self.best_position[idx] = self.position[idx].copy()
            self.best_fitness[idx] = self.fitness_fn(self.position[idx])

    # ------------------------------------------------------------------
    def run(self) -> PSOResult:
        p = self.p
        if p.max_iter <= 0:
            raise ValueError("Число итераций должно быть больше 0")
        if p.swarm_size < 2:
            raise ValueError("Размер роя должен быть не менее 2")

        self._initialize_swarm()
        self._find_global_best()

        history = np.zeros(p.max_iter + 1)
        history[0] = self.global_best_fitness

        no_improvement = 0
        mutation_count = 0
        previous_best = self.global_best_fitness
        mutations_applied = 0

        for it in range(1, p.max_iter + 1):
            weight = (p.inertia_start - (it / p.max_iter) * (p.inertia_start - p.inertia_end)
                      if p.use_adaptive_weight else p.inertia_weight)

            for i in range(p.swarm_size):
                self._update_particle(i, weight)

            history[it] = self.global_best_fitness

            if self.global_best_fitness < previous_best:
                no_improvement = 0
                previous_best = self.global_best_fitness
            else:
                no_improvement += 1

            if p.use_mutations and no_improvement >= p.max_iter_without_improvement:
                if mutation_count < MUTATION_AMT:
                    self._apply_mutation(mutation_count)
                    no_improvement = 0
                    mutation_count += 1
                    mutations_applied += 1
                    self._find_global_best()
                    previous_best = self.global_best_fitness
                    history[it] = self.global_best_fitness
                else:
                    mutation_count = 0
                    no_improvement = 0

        return PSOResult(
            best_position=self.global_best_position.copy(),
            best_fitness=self.global_best_fitness,
            history=history,
            mutations_applied=mutations_applied,
        )


def run_pso(fitness_fn: Callable[[np.ndarray], float], params: PSOParams,
            rng: Optional[np.random.Generator] = None) -> PSOResult:
    """Удобная обёртка: один запуск PSO/гибридного PSO."""
    engine = PSOEngine(fitness_fn, params, rng=rng)
    return engine.run()
