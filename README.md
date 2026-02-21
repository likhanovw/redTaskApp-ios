# Task Manager (iOS, SwiftUI, MVVM, Core Data)

Менеджер задач для iOS на SwiftUI с архитектурой MVVM и Core Data.

## Стек

- **Платформа:** iOS 16+
- **Язык:** Swift 5.9+
- **UI:** SwiftUI
- **Архитектура:** MVVM
- **Хранение данных:** Core Data
- **Среда:** Xcode 15+

## Требования

- Xcode 15+
- iOS 16+
- Swift 5.9+

## Структура проекта (что где лежит)

```
taskApp/
├── README.md
├── TaskApp/                          ← основной проект (его и открывать в Xcode)
│   ├── TaskApp.xcodeproj             ← двойной клик = открыть проект
│   └── TaskApp/                      ← папка с кодом (Xcode её уже видит)
│       ├── TaskAppApp.swift
│       ├── ContentView.swift
│       ├── Assets.xcassets/
│       ├── CoreData/                 (PersistenceController, TaskEntity, ChecklistItemEntity)
│       ├── ViewModels/               (TaskStore.swift)
│       └── Views/                    (TaskListView, TaskDetailView, CompletedTasksView)
└── TaskApp 16-17-34-139/            ← старый дубликат, можно не трогать или удалить
```

Весь код приложения «Задачи» теперь лежит внутри **TaskApp/TaskApp/** (во вложенной папке). Xcode при открытии проекта автоматически подхватывает все файлы из этой папки.

## Что сделать

1. Открой в Finder папку **taskApp**, затем папку **TaskApp**.
2. Двойной клик по файлу **TaskApp.xcodeproj** — откроется Xcode.
3. Выбери симулятор (например iPhone 16) и нажми **Run** (▶️).

Больше ничего настраивать не нужно: код на месте, проект один.

## Если Xcode показывает ошибки (Istat, viewContext, Hashable)

1. **Чистая пересборка:** в Xcode меню **Product** → **Clean Build Folder** (Shift+Cmd+K), затем снова **Run**.
2. Если ошибки в DerivedData остались: закрой Xcode, в Finder открой папку `~/Library/Developer/Xcode/DerivedData`, удали папку с именем **TaskApp-** (вся папка целиком). Открой проект снова и нажми **Run**.

## Структура

- **TaskAppApp.swift** — точка входа, окружение Core Data и TaskStore.
- **ContentView.swift** — TabView (Задачи / Архив).
- **CoreData/** — модель (TaskEntity, ChecklistItemEntity), PersistenceController (модель задаётся в коде).
- **ViewModels/TaskStore.swift** — CRUD, чеклист, таймер, локальные уведомления (>2 ч).
- **Views/**
  - **TaskListView** — список активных задач, drag-and-drop, свайпы, переход в детали.
  - **TaskDetailView** — редактирование, чеклист, таймер, завершение задачи.
  - **CompletedTasksView** — архив, восстановление, удаление.

## Функционал

- Задачи: название, описание, порядок, общее время, дата создания/завершения.
- Чеклист внутри задачи: пункты с порядком и выполнением.
- Таймер: старт/стоп, текущая сессия и общее время; напоминание при работе таймера > 2 часов.
- Анимации: появление/исчезновение списков, прогресс чеклиста, пульсация кнопки таймера.

## Локальные уведомления

При работе таймера дольше 2 часов планируется локальное уведомление. При первом запросе система запросит разрешение на уведомления.
