# -*- coding: utf-8 -*-
"""
Тестовые функции для оптимизации методом роя частиц (PSO).

Первые 21 функция — прямой перенос формул из исходной Delphi-программы
(PartialSwarmInt.pas). Функции с 22 по 29 — новые, добавленные при
расширении отчёта (аналоги из библиотеки pyOptiGTest / классического
набора бенчмарков для метаэвристик).

Каждая запись реестра TEST_FUNCTIONS — это объект FunctionSpec с полями:
    name        — отображаемое имя (как в комбобоксе)
    func        — вызываемая функция f(x: np.ndarray) -> float
    min_bound   — нижняя граница по каждой координате
    max_bound   — верхняя граница по каждой координате
    fixed_dim   — None, если функция работает в любой размерности,
                  иначе обязательная размерность (например, 2 для 2D-функций)
    min_dim     — минимально допустимая размерность (для функций вида "по парам")
    max_velocity_override / search_range_override —
                  как в оригинале, для функции Швефеля переопределяются
                  MaxVelocity и SearchRange по умолчанию
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Callable, Optional

import numpy as np


@dataclass
class FunctionSpec:
    name: str
    func: Callable[[np.ndarray], float]
    min_bound: float
    max_bound: float
    fixed_dim: Optional[int] = None
    min_dim: Optional[int] = None
    max_velocity_override: Optional[float] = None
    search_range_override: Optional[float] = None


# ============================================================
# 0-20: функции из оригинальной Delphi-программы
# ============================================================

def sphere(x: np.ndarray) -> float:
    return float(np.sum(x * x))


def rosenbrock(x: np.ndarray) -> float:
    if len(x) < 2:
        return 0.0
    xi, xi1 = x[:-1], x[1:]
    return float(np.sum(100.0 * (xi1 - xi ** 2) ** 2 + (1 - xi) ** 2))


def rastrigin(x: np.ndarray) -> float:
    n = len(x)
    return float(10 * n + np.sum(x * x - 10 * np.cos(2 * np.pi * x)))


def griewank(x: np.ndarray) -> float:
    i = np.arange(1, len(x) + 1)
    s = np.sum(x * x) / 4000.0
    p = np.prod(np.cos(x / np.sqrt(i)))
    return float(1 + s - p)


def ackley(x: np.ndarray) -> float:
    n = len(x)
    if n == 0:
        return 0.0
    sum1 = np.sum(x * x)
    sum2 = np.sum(np.cos(2 * np.pi * x))
    return float(-20 * np.exp(-0.2 * np.sqrt(sum1 / n)) - np.exp(sum2 / n) + 20 + np.e)


def schwefel(x: np.ndarray) -> float:
    n = len(x)
    s = np.sum(x * np.sin(np.sqrt(np.abs(x))))
    return float(418.9829 * n - s)


def levy(x: np.ndarray) -> float:
    n = len(x)
    if n == 0:
        return 0.0
    result = math.sin(3 * math.pi * x[0]) ** 2
    for i in range(n - 1):
        result += (x[i] - 1) ** 2 * (1 + math.sin(3 * math.pi * x[i + 1]) ** 2)
    result += (x[n - 1] - 1) ** 2 * (1 + math.sin(2 * math.pi * x[n - 1]) ** 2)
    return float(result)


def himmelblau(x: np.ndarray) -> float:
    if len(x) < 2:
        return 1000.0
    if len(x) == 2:
        return float((x[0] ** 2 + x[1] - 11) ** 2 + (x[0] + x[1] ** 2 - 7) ** 2)
    return float((x[0] ** 2 + x[1] - 11) ** 2 + (x[0] + x[1] ** 2 - 7) ** 2 + (len(x) - 2) * 1000)


def michalewicz(x: np.ndarray, m: float = 10) -> float:
    n = len(x)
    i = np.arange(1, n + 1)
    s = np.sum(np.sin(x) * np.sin(i * x * x / np.pi) ** (2 * m))
    return float(-s)


def schaffer_n2(x: np.ndarray) -> float:
    n = len(x)
    if n < 2:
        return 1000.0
    xi, xi1 = x[:-1], x[1:]
    num = np.sin(xi ** 2 - xi1 ** 2) ** 2 - 0.5
    den = (1 + 0.001 * (xi ** 2 + xi1 ** 2)) ** 2
    return float(np.sum(0.5 + num / den))


def drop_wave(x: np.ndarray) -> float:
    if len(x) < 2:
        return 1000.0
    r2 = x[0] ** 2 + x[1] ** 2
    if r2 == 0:
        return -1.0
    return float(-(1 + math.cos(12 * math.sqrt(r2))) / (0.5 * r2 + 2))


def alpine_n1(x: np.ndarray) -> float:
    return float(np.sum(np.abs(x * np.sin(x) + 0.1 * x)))


def brown(x: np.ndarray) -> float:
    n = len(x)
    s = 0.0
    for i in range(n - 1):
        s += (x[i] ** 2) ** (x[i + 1] ** 2 + 1) + (x[i + 1] ** 2) ** (x[i] ** 2 + 1)
    return float(s)


def powell(x: np.ndarray) -> float:
    n = len(x)
    s = 0.0
    i = 0
    while i <= n - 4:
        s += (x[i] + 10 * x[i + 1]) ** 2 + 5 * (x[i + 2] - x[i + 3]) ** 2 \
            + (x[i + 1] - 2 * x[i + 2]) ** 4 + 10 * (x[i] - x[i + 3]) ** 4
        i += 4
    return float(s)


def dixon_price(x: np.ndarray) -> float:
    n = len(x)
    if n < 2:
        return 1000.0
    s = (x[0] - 1) ** 2
    for i in range(1, n):
        s += (i + 1) * (2 * x[i] ** 2 - x[i - 1]) ** 2
    return float(s)


def levy_n13(x: np.ndarray) -> float:
    n = len(x)
    if n < 2:
        return 1000.0
    s = math.sin(3 * math.pi * x[0]) ** 2
    for i in range(n - 1):
        s += (x[i] - 1) ** 2 * (1 + math.sin(3 * math.pi * x[i + 1]) ** 2)
    s += (x[n - 1] - 1) ** 2 * (1 + math.sin(2 * math.pi * x[n - 1]) ** 2)
    return float(0.1 * s)


def bohachevsky_n1(x: np.ndarray) -> float:
    n = len(x)
    if n < 2:
        return 1000.0
    xi, xi1 = x[:-1], x[1:]
    s = xi ** 2 + 2 * xi1 ** 2 - 0.3 * np.cos(3 * np.pi * xi) - 0.4 * np.cos(4 * np.pi * xi1) + 0.7
    return float(np.sum(s))


def perm_0_d_beta(x: np.ndarray, beta: float = 0.5) -> float:
    n = len(x)
    total = 0.0
    for i in range(1, n + 1):
        inner = 0.0
        for j in range(1, n + 1):
            term = j ** i + beta
            inner += term * (x[j - 1] ** i - (1.0 / j) ** i)
        total += inner ** 2
    return float(total)


def rotated_hyper_ellipsoid(x: np.ndarray) -> float:
    n = len(x)
    total = 0.0
    for i in range(n):
        total += np.sum(x[: i + 1] ** 2)
    return float(total)


def sum_of_different_powers(x: np.ndarray) -> float:
    i = np.arange(len(x))
    return float(np.sum(np.abs(x) ** (i + 2)))


def trid(x: np.ndarray) -> float:
    sum1 = np.sum((x - 1) ** 2)
    sum2 = np.sum(x[1:] * x[:-1])
    return float(sum1 - sum2)


# ============================================================
# 21-28: новые функции, добавленные при расширении отчёта
# (стандартные бенчмарки, аналогичные включённым в pyOptiGTest)
# ============================================================

def beale(x: np.ndarray) -> float:
    if len(x) < 2:
        return 1000.0
    x1, x2 = x[0], x[1]
    return float((1.5 - x1 + x1 * x2) ** 2
                 + (2.25 - x1 + x1 * x2 ** 2) ** 2
                 + (2.625 - x1 + x1 * x2 ** 3) ** 2)


def booth(x: np.ndarray) -> float:
    if len(x) < 2:
        return 1000.0
    x1, x2 = x[0], x[1]
    return float((x1 + 2 * x2 - 7) ** 2 + (2 * x1 + x2 - 5) ** 2)


def matyas(x: np.ndarray) -> float:
    if len(x) < 2:
        return 1000.0
    x1, x2 = x[0], x[1]
    return float(0.26 * (x1 ** 2 + x2 ** 2) - 0.48 * x1 * x2)


def zakharov(x: np.ndarray) -> float:
    i = np.arange(1, len(x) + 1)
    s1 = np.sum(x * x)
    s2 = np.sum(0.5 * i * x)
    return float(s1 + s2 ** 2 + s2 ** 4)


def easom(x: np.ndarray) -> float:
    if len(x) < 2:
        return 1000.0
    x1, x2 = x[0], x[1]
    return float(-math.cos(x1) * math.cos(x2)
                 * math.exp(-((x1 - math.pi) ** 2 + (x2 - math.pi) ** 2)))


def bohachevsky_n2(x: np.ndarray) -> float:
    n = len(x)
    if n < 2:
        return 1000.0
    xi, xi1 = x[:-1], x[1:]
    s = xi ** 2 + 2 * xi1 ** 2 - 0.3 * np.cos(3 * np.pi * xi) * np.cos(4 * np.pi * xi1) + 0.3
    return float(np.sum(s))


def salomon(x: np.ndarray) -> float:
    r = math.sqrt(float(np.sum(x * x)))
    return float(1 - math.cos(2 * math.pi * r) + 0.1 * r)


def eggholder(x: np.ndarray) -> float:
    if len(x) < 2:
        return 1000.0
    x1, x2 = x[0], x[1]
    t1 = -(x2 + 47) * math.sin(math.sqrt(abs(x1 / 2 + (x2 + 47))))
    t2 = -x1 * math.sin(math.sqrt(abs(x1 - (x2 + 47))))
    return float(t1 + t2)


# ============================================================
# Реестр всех функций — порядок совпадает с комбобоксом
# ============================================================

TEST_FUNCTIONS: list[FunctionSpec] = [
    FunctionSpec("Сферическая", sphere, -10.0, 10.0),
    FunctionSpec("Розенброка", rosenbrock, -10.0, 10.0),
    FunctionSpec("Растригина", rastrigin, -10.0, 10.0),
    FunctionSpec("Гриванк", griewank, -10.0, 10.0),
    FunctionSpec("Экли", ackley, -10.0, 10.0),
    FunctionSpec("Швефеля", schwefel, -500.0, 500.0,
                 max_velocity_override=100.0, search_range_override=500.0),
    FunctionSpec("Леви", levy, -10.0, 10.0),
    FunctionSpec("Химмельблау", himmelblau, -10.0, 10.0, fixed_dim=2),
    FunctionSpec("Михалевича", michalewicz, 0.0, math.pi),
    FunctionSpec("Шаффера N.2", schaffer_n2, -100.0, 100.0, min_dim=2),
    FunctionSpec("Падающая волна", drop_wave, -5.12, 5.12, fixed_dim=2),
    FunctionSpec("Альпийская N.1", alpine_n1, -10.0, 10.0),
    FunctionSpec("Брауна", brown, -1.0, 4.0),
    FunctionSpec("Пауэлла", powell, -4.0, 5.0),
    FunctionSpec("Диксона-Прайса", dixon_price, -10.0, 10.0, min_dim=2),
    FunctionSpec("Леви N.13", levy_n13, -10.0, 10.0),
    FunctionSpec("Бочачевского N.1", bohachevsky_n1, -100.0, 100.0),
    FunctionSpec("Перм 0, D, Бета", perm_0_d_beta, None, None),  # диапазон = [-D, D], задаётся динамически
    FunctionSpec("Вращённый гиперэллипсоид", rotated_hyper_ellipsoid, -65.536, 65.536),
    FunctionSpec("Сумма разных степеней", sum_of_different_powers, -1.0, 1.0),
    FunctionSpec("Трид", trid, None, None),  # диапазон = [-D^2, D^2], задаётся динамически
    # --- новые функции ---
    FunctionSpec("Била (Beale)", beale, -4.5, 4.5, fixed_dim=2),
    FunctionSpec("Бута (Booth)", booth, -10.0, 10.0, fixed_dim=2),
    FunctionSpec("Матьяса (Matyas)", matyas, -10.0, 10.0, fixed_dim=2),
    FunctionSpec("Захарова (Zakharov)", zakharov, -5.0, 10.0),
    FunctionSpec("Исома (Easom)", easom, -100.0, 100.0, fixed_dim=2),
    FunctionSpec("Бочачевского N.2", bohachevsky_n2, -100.0, 100.0),
    FunctionSpec("Саломона (Salomon)", salomon, -100.0, 100.0),
    FunctionSpec("Эггхолдера (Eggholder)", eggholder, -512.0, 512.0, fixed_dim=2),
]


def get_bounds(spec: FunctionSpec, dimension: int) -> tuple[float, float]:
    """Возвращает (min, max) границы для функции с динамическим диапазоном."""
    if spec.name == "Перм 0, D, Бета":
        return -float(dimension), float(dimension)
    if spec.name == "Трид":
        d2 = float(dimension) ** 2
        return -d2, d2
    return spec.min_bound, spec.max_bound


def resolve_dimension(spec: FunctionSpec, requested_dim: int) -> int:
    """Приводит запрошенную размерность к допустимой для данной функции."""
    dim = requested_dim
    if spec.fixed_dim is not None:
        dim = spec.fixed_dim
    elif spec.min_dim is not None and dim < spec.min_dim:
        dim = spec.min_dim
    return max(dim, 1)
