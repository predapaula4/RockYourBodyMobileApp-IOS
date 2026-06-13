import SwiftUI

struct ExerciseOverviewRowView: View {
    let exercise: ExerciseOverviewItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exercise.dayOfExercise)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(exercise.bodyPart)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(exercise.exerciseName)
                .font(.headline)
                .foregroundColor(.white)
            
            Text("\(exercise.numberOfSeries) Series x \(exercise.numberOfRepsPerSerie) Reps @ \(exercise.weightForEachRep) kg")
                .font(.subheadline)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
    }
}
