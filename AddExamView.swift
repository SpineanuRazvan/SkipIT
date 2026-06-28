import SwiftUI
import SwiftData
import WidgetKit

struct AddExamView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \Subject.name) var availableSubjects: [Subject]
    
    var examToEdit: Exam? // Opțional pentru editare

    @State private var selectedSubjectName = ""
    @State private var examDate = Date()
    @State private var room = ""
    @State private var examType = "Exam"

    let examTypes = ["Exam", "Partial", "Colloquium", "Project Presentation"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Exam Details") {
                    Picker("Subject", selection: $selectedSubjectName) {
                        if availableSubjects.isEmpty {
                            Text("No subjects found").tag("")
                        } else {
                            Text("Select a subject").tag("")
                            
                           
                            let uniqueSubjectNames = Array(Set(availableSubjects.map { $0.name })).sorted()
                            
                            ForEach(uniqueSubjectNames, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                    }
                    
                    Picker("Type", selection: $examType) {
                        ForEach(examTypes, id: \.self) { Text($0) }
                    }
                }
                
                Section("Logistics") {
                    TextField("Room / Hall", text: $room)
                    DatePicker("Date & Time", selection: $examDate)
                }
            }
            .navigationTitle(examToEdit == nil ? "Add Exam" : "Edit Exam")
            .onAppear {
                if let exam = examToEdit {
                    selectedSubjectName = exam.subjectName
                    examDate = exam.date
                    room = exam.room
                    examType = exam.type
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(examToEdit == nil ? "Save" : "Update") {
                        if let exam = examToEdit {
                            exam.subjectName = selectedSubjectName
                            exam.date = examDate
                            exam.room = room
                            exam.type = examType
                        } else {
                            let newExam = Exam(subjectName: selectedSubjectName, date: examDate, room: room, type: examType)
                            modelContext.insert(newExam)
                        }
                        dismiss()
                    }
                    .disabled(selectedSubjectName.isEmpty || room.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
