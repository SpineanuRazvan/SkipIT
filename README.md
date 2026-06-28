#SkipIT: Sistem Inteligent de Monitorizare Academică

##SkipIT este o aplicație mobilă nativă pentru iOS, concepută special pentru a eficientiza managementul prezențelor, calculul predictiv al absențelor permise și monitorizarea parcursului universitar al studenților. 

##Spre deosebire de uneltele tradiționale care necesită introducere manuală și  repetitivă, SkipIT necesită interacțiune minimă din partea utilizatorului, reducând rata de abandon.



##1. Caracteristici Principale

- Notificări Interactive Contextuale (Actionable Notifications):
    - Sistemul calculează momentul finalizării cursurilor pe baza orarului și trimite o alertă push direct pe ecranul blocat. Utilizatorul poate confirma prezența printr-o singură atingere (Yes/No), fără a deschide aplicația.
- Import de Orar Automatizat (Google Gemini API):
    - Cu ajutorul modelul Gemini 2.5 Flash (folosind Structured Outputs pentru consistență JSON) utilizatorul poate incărca orarul in format PDF sau imagine, iar modelul de inteligență artificială filtrează automat cursurile în funcție de grupa din care face parte utilizatorul. 
- Sincronizare Calendar (EventKit):
    - Integrare nativă securizată cu Apple Calendar și Google Calendar pentru afișarea evenimentelor personale în paralel cu orele de curs, facilitând identificarea conflictelor de timp.
- Motor de Calcul Predictiv ("Skips Left"):
    - Monitorizare a numărului de prezențe acumulate și contorizarea numărului de absențe pe care le mai poate face studentul astfel încât să atingă numărul minim de prezențe cerute pentru a susține examenul. (Bazat pe numărul de săptamâni ramase din semestru)
- Extensii pe Home Screen (WidgetKit):
    - Widget-uri native (Small/Medium/Large) bazate pe o arhitectură de sincronizare inter-proces, oferind acces pasiv instantaneu la programul zilei curente și starea prezențelor.
- Interfață Modernă (Liquid Glass):
    - Design minimalist construit integral în SwiftUI, utilizând efecte de materiale translucide (`.ultraThinMaterial`) și grafică vectorială adaptivă randată direct pe GPU.


##2.  Arhitectură și Tehnologii

Aplicația este structurată pe baza modelului arhitectural MVVM (Model-View-ViewModel), respectând regulile stricte de concurență din Swift 6 Mode

- **Limbaj de programare:** Swift 5.10 / 6
- **Interfață grafică:** SwiftUI (Declarativ)
- **Persistența datelor:** SwiftData (Mapare obiectual-relațională nativă)
- **Sincronizare inter-proces:** App Groups (pentru partajarea bazei de date `.sqlite` între aplicația principală, extensia de notificare și widget-uri)
- **Integrare externă:** EventKit, UserNotificationsUI, WidgetKit
- **Procesare AI:** Gemini 2.5 Flash API (REST via URLSession)


##3. Ghid de Instalare și Rulare

Pentru a rula și compila proiectul local, aveți nevoie de un calculator Mac cu Xcode 15.0+ și iOS 17.0+ (sau un simulator).

    a) Clonarea repository-ului:
 
```bash
git clone https://github.com/SpineanuRazvan/SkipIT.git
cd SkipIT
```

    b) Configurare Signing & Capabilities:
Pentru ca funcționalitățile de fundal și widget-urile să funcționeze corect, asigurați-vă că în secțiunea Signing & Capabilities din Xcode sunt configurate corect următoarele:
- App Groups: Identificatorul trebuie să fie setat pe `group.com.razvan.skipit` pentru toate target-urile (Aplicație, Extensie Notificări, Widget).
- Calendars / Notifications: Permisiunile de sistem sunt cerute automat la primul onboarding în aplicație.

    c) Configurarea Cheii API Gemini
Pentru a utiliza funcția de import automatizat al orarului prin inteligență artificială, deschideți fișierul `GeminiParserService.swift` și introduceți o cheie validă Google AI Studio în constanta dedicată:
```swift
let apiKey = //insert API Key
```

    d) Compilare
- Deschideți proiectul în Xcode (`SkipIT.xcodeproj`).
- Selectați schema principală **SkipIT**.
- Alegeți un dispozitiv de testare din bara de sus.
- Apăsați `Cmd + R` pentru compilare și rulare.

---

##4. Autor și Coordonare:

- Absolvent: Spineanu Mihai-Răzvan (Specializarea Informatică în limba română)
- Coordonator: Lect. Dr. Adrian Spătaru
- Instituție: Universitatea de Vest din Timișoara, Facultatea de Informatică
- An universitar: 2025-2026
