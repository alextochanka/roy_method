# -*- coding: utf-8 -*-
"""
Графический интерфейс на Tkinter — аналог исходной VCL-формы PartialSwarmInt.

Расположение элементов повторяет оригинал: слева — панель параметров
(выбор функции, размерность, размер роя, итерации, c1/c2, MaxVelocity,
SearchRange, инерция, штраф, мутации, число прогонов), справа —
результаты (таблица прогонов, график сходимости, текстовая сводка).

Дополнительно к оригиналу: флажок "Сравнить classic vs hybrid" — запускает
оба режима на одинаковых параметрах и накладывает графики сходимости друг
на друга для отчёта.
"""

from __future__ import annotations

import csv
import tkinter as tk
from tkinter import ttk, messagebox, filedialog

import numpy as np
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

from pso_engine import PSOParams, run_pso
from test_functions import TEST_FUNCTIONS, get_bounds, resolve_dimension


class PSOApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Оптимизация методом роя частиц (PSO) — Python")
        self.geometry("1150x720")
        self.minsize(1000, 650)

        self.rng = np.random.default_rng()
        self.last_results_classic: list[float] = []
        self.last_results_hybrid: list[float] = []
        self.last_func_name = ""

        # Пользовательские значения MaxVelocity / SearchRange,
        # которые не должны теряться при переключении на функцию с override.
        self._user_maxvel = 4.0
        self._user_range = 10.0

        self._build_layout()

        # Применяем override для функции, выбранной по умолчанию (индекс 0).
        self._apply_function_overrides(TEST_FUNCTIONS[self.cb_function.current()])

    # ------------------------------------------------------------------
    # UI layout
    # ------------------------------------------------------------------
    def _build_layout(self):
        root = ttk.Frame(self, padding=8)
        root.pack(fill="both", expand=True)

        left = ttk.Frame(root, width=320)
        left.pack(side="left", fill="y", padx=(0, 8))
        right = ttk.Frame(root)
        right.pack(side="left", fill="both", expand=True)

        self._build_param_panel(left)
        self._build_results_panel(right)

    def _build_param_panel(self, parent):
        row = 0

        def add_label(text):
            nonlocal row
            ttk.Label(parent, text=text).grid(row=row, column=0, sticky="w", pady=2)

        def add_row(text, widget):
            nonlocal row
            add_label(text)
            widget.grid(row=row, column=1, sticky="ew", pady=2)
            row += 1

        parent.columnconfigure(1, weight=1)

        ttk.Label(parent, text="Тестовая функция", font=("Segoe UI", 9, "bold")).grid(
            row=row, column=0, columnspan=2, sticky="w", pady=(0, 4))
        row += 1
        self.cb_function = ttk.Combobox(parent, values=[s.name for s in TEST_FUNCTIONS],
                                         state="readonly")
        self.cb_function.current(0)
        self.cb_function.grid(row=row, column=0, columnspan=2, sticky="ew", pady=(0, 8))
        self.cb_function.bind("<<ComboboxSelected>>", self._on_function_changed)
        row += 1

        self.sv_dimension = tk.IntVar(value=5)
        add_row("Размерность:", ttk.Spinbox(parent, from_=1, to=50, textvariable=self.sv_dimension))
        self.sv_swarm = tk.IntVar(value=40)
        add_row("Размер роя:", ttk.Spinbox(parent, from_=2, to=1000, textvariable=self.sv_swarm))
        self.sv_iter = tk.IntVar(value=200)
        add_row("Итераций:", ttk.Spinbox(parent, from_=1, to=100000, textvariable=self.sv_iter))

        self.sv_c1 = tk.DoubleVar(value=1.5)
        add_row("Самоуверенность c1:", ttk.Entry(parent, textvariable=self.sv_c1))
        self.sv_c2 = tk.DoubleVar(value=1.5)
        add_row("Социальность c2:", ttk.Entry(parent, textvariable=self.sv_c2))

        self.sv_maxvel = tk.DoubleVar(value=4.0)
        self.ent_maxvel = ttk.Entry(parent, textvariable=self.sv_maxvel)
        add_row("Макс. скорость:", self.ent_maxvel)

        self.sv_range = tk.DoubleVar(value=10.0)
        self.ent_range = ttk.Entry(parent, textvariable=self.sv_range)
        add_row("Диапазон поиска:", self.ent_range)

        self.sv_inertia = tk.DoubleVar(value=0.7)
        add_row("Инерц. вес (фикс.):", ttk.Entry(parent, textvariable=self.sv_inertia))
        self.sv_inertia_start = tk.DoubleVar(value=0.9)
        add_row("Инерция: начало:", ttk.Entry(parent, textvariable=self.sv_inertia_start))
        self.sv_inertia_end = tk.DoubleVar(value=0.4)
        add_row("Инерция: конец:", ttk.Entry(parent, textvariable=self.sv_inertia_end))

        self.sv_penalty_ratio = tk.DoubleVar(value=100.0)
        add_row("Коэфф. штрафа:", ttk.Entry(parent, textvariable=self.sv_penalty_ratio))
        self.sv_no_improve = tk.IntVar(value=20)
        add_row("Итер. без улучш.:", ttk.Spinbox(parent, from_=1, to=100000,
                                                  textvariable=self.sv_no_improve))
        self.sv_runs = tk.IntVar(value=10)
        add_row("Число прогонов:", ttk.Spinbox(parent, from_=1, to=1000, textvariable=self.sv_runs))

        row += 1
        self.bv_adaptive = tk.BooleanVar(value=True)
        ttk.Checkbutton(parent, text="Адаптивный инерционный вес",
                         variable=self.bv_adaptive).grid(row=row, column=0, columnspan=2,
                                                          sticky="w")
        row += 1
        self.bv_penalty = tk.BooleanVar(value=False)
        ttk.Checkbutton(parent, text="Штрафная функция (границы)",
                         variable=self.bv_penalty).grid(row=row, column=0, columnspan=2,
                                                         sticky="w")
        row += 1
        self.bv_compare = tk.BooleanVar(value=True)
        ttk.Checkbutton(parent, text="Сравнить classic vs hybrid",
                         variable=self.bv_compare).grid(row=row, column=0, columnspan=2,
                                                         sticky="w", pady=(0, 8))
        row += 1

        btns = ttk.Frame(parent)
        btns.grid(row=row, column=0, columnspan=2, sticky="ew", pady=8)
        ttk.Button(btns, text="Запустить", command=self.on_run).pack(side="left", expand=True,
                                                                      fill="x", padx=(0, 4))
        ttk.Button(btns, text="Очистить", command=self.on_clear).pack(side="left", expand=True,
                                                                       fill="x", padx=4)
        row += 1
        ttk.Button(parent, text="Сохранить результаты...",
                   command=self.on_save).grid(row=row, column=0, columnspan=2, sticky="ew")
        row += 1

        self.lbl_status = ttk.Label(parent, text="Готово", foreground="#333")
        self.lbl_status.grid(row=row, column=0, columnspan=2, sticky="w", pady=(8, 0))

    def _build_results_panel(self, parent):
        top = ttk.Frame(parent)
        top.pack(fill="both", expand=True)

        table_frame = ttk.Frame(top, width=260)
        table_frame.pack(side="left", fill="y", padx=(0, 8))
        ttk.Label(table_frame, text="Прогоны", font=("Segoe UI", 9, "bold")).pack(anchor="w")
        columns = ("run", "classic", "hybrid")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings", height=18)
        for col, title, width in [("run", "№", 40), ("classic", "Classic", 100),
                                   ("hybrid", "Hybrid", 100)]:
            self.tree.heading(col, text=title)
            self.tree.column(col, width=width, anchor="center")
        self.tree.pack(fill="y", expand=True)

        chart_frame = ttk.Frame(top)
        chart_frame.pack(side="left", fill="both", expand=True)
        self.figure = Figure(figsize=(5.5, 4.2), dpi=100)
        self.ax = self.figure.add_subplot(111)
        self.ax.set_title("График сходимости")
        self.ax.set_xlabel("Итерация")
        self.ax.set_ylabel("Лучшее значение")
        self.canvas = FigureCanvasTkAgg(self.figure, master=chart_frame)
        self.canvas.get_tk_widget().pack(fill="both", expand=True)

        ttk.Label(parent, text="Сводка", font=("Segoe UI", 9, "bold")).pack(anchor="w", pady=(8, 0))
        self.txt_summary = tk.Text(parent, height=10, wrap="word")
        self.txt_summary.pack(fill="both", expand=False)

    # ------------------------------------------------------------------
    # Function override sync
    # ------------------------------------------------------------------
    def _on_function_changed(self, event=None):
        """При смене функции обновляет поля MaxVelocity/SearchRange
        в соответствии с override из test_functions.py."""
        idx = self.cb_function.current()
        if idx < 0:
            return
        spec = TEST_FUNCTIONS[idx]

        # Сохраняем текущие значения как "пользовательские",
        # но только если они сейчас не переопределены функцией
        # (иначе затрём пользовательское значение значением override).
        if spec.max_velocity_override is None:
            try:
                self._user_maxvel = self.sv_maxvel.get()
            except tk.TclError:
                pass
        if spec.search_range_override is None:
            try:
                self._user_range = self.sv_range.get()
            except tk.TclError:
                pass

        self._apply_function_overrides(spec)

    def _apply_function_overrides(self, spec):
        """Показывает в полях актуальные значения с учётом override
        и блокирует поля, если функция их жёстко задаёт."""
        if spec.max_velocity_override is not None:
            self.sv_maxvel.set(spec.max_velocity_override)
            self.ent_maxvel.state(["disabled"])
        else:
            self.sv_maxvel.set(self._user_maxvel)
            self.ent_maxvel.state(["!disabled"])

        if spec.search_range_override is not None:
            self.sv_range.set(spec.search_range_override)
            self.ent_range.state(["disabled"])
        else:
            self.sv_range.set(self._user_range)
            self.ent_range.state(["!disabled"])

    # ------------------------------------------------------------------
    # Logic
    # ------------------------------------------------------------------
    def _build_params(self, spec, dim: int) -> PSOParams:
        lo, hi = get_bounds(spec, dim)
        search_range = (spec.search_range_override
                        if spec.search_range_override is not None
                        else self.sv_range.get())
        max_velocity = (spec.max_velocity_override
                        if spec.max_velocity_override is not None
                        else self.sv_maxvel.get())
        min_values = np.full(dim, lo) if self.bv_penalty.get() else None
        max_values = np.full(dim, hi) if self.bv_penalty.get() else None

        return PSOParams(
            dimension=dim,
            swarm_size=self.sv_swarm.get(),
            max_iter=self.sv_iter.get(),
            self_confidence=self.sv_c1.get(),
            social_confidence=self.sv_c2.get(),
            max_velocity=max_velocity,
            search_range=search_range,
            inertia_weight=self.sv_inertia.get(),
            inertia_start=self.sv_inertia_start.get(),
            inertia_end=self.sv_inertia_end.get(),
            use_adaptive_weight=self.bv_adaptive.get(),
            use_penalty=self.bv_penalty.get(),
            max_iter_without_improvement=self.sv_no_improve.get(),
            penalty_ratio=self.sv_penalty_ratio.get(),
            min_values=min_values,
            max_values=max_values,
            use_mutations=False,  # переопределяется ниже для каждого режима
        )

    def on_run(self):
        try:
            idx = self.cb_function.current()
            if idx < 0:
                messagebox.showwarning("Внимание", "Выберите тестовую функцию")
                return
            spec = TEST_FUNCTIONS[idx]
            dim = resolve_dimension(spec, self.sv_dimension.get())
            if dim != self.sv_dimension.get():
                self.sv_dimension.set(dim)
                messagebox.showinfo("Размерность скорректирована",
                                     f"Функция «{spec.name}» требует размерность {dim}.")

            if self.sv_swarm.get() < 2:
                messagebox.showwarning("Внимание", "Размер роя должен быть не менее 2")
                return
            if self.sv_c1.get() <= 0 or self.sv_c2.get() <= 0:
                messagebox.showwarning("Внимание", "c1 и c2 должны быть больше 0")
                return
            if self.sv_iter.get() <= 0:
                messagebox.showwarning("Внимание", "Число итераций должно быть больше 0")
                return

            runs = self.sv_runs.get()
            compare = self.bv_compare.get()
            modes = ["classic", "hybrid"] if compare else ["hybrid"]

            self.tree.delete(*self.tree.get_children())
            results = {"classic": [], "hybrid": []}
            last_history = {}
            last_best_pos = {}

            for run in range(runs):
                self.lbl_status.config(text=f"Прогон {run + 1} / {runs}")
                self.update_idletasks()
                row_vals = [run + 1, "", ""]
                for mode in modes:
                    params = self._build_params(spec, dim)
                    params.use_mutations = (mode == "hybrid")
                    res = run_pso(spec.func, params, rng=self.rng)
                    results[mode].append(res.best_fitness)
                    last_history[mode] = res.history
                    last_best_pos[mode] = res.best_position
                    row_vals[1 if mode == "classic" else 2] = f"{res.best_fitness:.6f}"
                self.tree.insert("", "end", values=row_vals)

            self.last_results_classic = results.get("classic", [])
            self.last_results_hybrid = results.get("hybrid", [])
            self.last_func_name = spec.name

            self._draw_convergence(last_history)
            self._show_summary(spec.name, dim, modes, results, last_best_pos)

            self.lbl_status.config(text="Готово: " + spec.name)
        except tk.TclError:
            messagebox.showerror("Ошибка", "Проверьте, что все числовые поля заполнены корректно")
        except Exception as exc:  # noqa: BLE001
            messagebox.showerror("Ошибка", str(exc))
            self.lbl_status.config(text="Ошибка выполнения")

    def _draw_convergence(self, histories: dict[str, np.ndarray]):
        self.ax.clear()
        self.ax.set_title("График сходимости (последний прогон)")
        self.ax.set_xlabel("Итерация")
        self.ax.set_ylabel("Лучшее значение")
        colors = {"classic": "#1f77b4", "hybrid": "#d62728"}
        labels = {"classic": "Classic PSO", "hybrid": "Hybrid PSO"}
        for mode, hist in histories.items():
            self.ax.plot(hist, label=labels[mode], color=colors[mode])
        if len(histories) > 1:
            self.ax.legend()
        self.ax.grid(True, alpha=0.3)
        self.canvas.draw()

    def _show_summary(self, func_name, dim, modes, results, best_pos):
        self.txt_summary.delete("1.0", "end")
        lines = [f"Функция: {func_name}", f"Размерность: {dim}",
                 f"Размер роя: {self.sv_swarm.get()}", f"Итераций: {self.sv_iter.get()}",
                 f"Прогонов: {self.sv_runs.get()}", "-" * 40]
        for mode in modes:
            arr = np.array(results[mode])
            label = "Classic PSO" if mode == "classic" else "Hybrid PSO"
            lines.append(f"[{label}]")
            lines.append(f"  среднее:      {arr.mean():.6f}")
            lines.append(f"  минимум:      {arr.min():.6f}")
            lines.append(f"  максимум:     {arr.max():.6f}")
            lines.append(f"  ср.кв.откл.:  {arr.std():.6f}")
            pos_str = ", ".join(f"{v:.4f}" for v in best_pos[mode])
            lines.append(f"  лучшая точка: [{pos_str}]")
            lines.append("")
        self.txt_summary.insert("1.0", "\n".join(lines))

    def on_clear(self):
        self.tree.delete(*self.tree.get_children())
        self.txt_summary.delete("1.0", "end")
        self.ax.clear()
        self.ax.set_title("График сходимости")
        self.ax.set_xlabel("Итерация")
        self.ax.set_ylabel("Лучшее значение")
        self.canvas.draw()
        self.last_results_classic = []
        self.last_results_hybrid = []
        self.lbl_status.config(text="Очищено")

    def on_save(self):
        if not self.last_results_classic and not self.last_results_hybrid:
            messagebox.showinfo("Нет данных", "Сначала выполните запуск")
            return
        path = filedialog.asksaveasfilename(defaultextension=".csv",
                                             filetypes=[("CSV файлы", "*.csv")])
        if not path:
            return
        with open(path, "w", newline="", encoding="utf-8-sig") as f:
            writer = csv.writer(f, delimiter=";")
            writer.writerow(["Функция", self.last_func_name])
            writer.writerow(["Прогон", "Classic", "Hybrid"])
            n = max(len(self.last_results_classic), len(self.last_results_hybrid))
            for i in range(n):
                c = self.last_results_classic[i] if i < len(self.last_results_classic) else ""
                h = self.last_results_hybrid[i] if i < len(self.last_results_hybrid) else ""
                writer.writerow([i + 1, c, h])
        messagebox.showinfo("Сохранено", f"Результаты сохранены в {path}")


if __name__ == "__main__":
    app = PSOApp()
    app.mainloop()