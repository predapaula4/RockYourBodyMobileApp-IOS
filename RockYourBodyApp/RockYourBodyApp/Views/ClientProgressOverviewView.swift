import SwiftUI
import Charts
import PhotosUI

struct ClientProgressOverviewView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var chartData: ClientProgressChartResponse?
    @State private var foldersList: [String] = ["General Progress"]
    @State private var selectedFolder: String = "General Progress"
    @State private var photosList: [ProgressPhotoResponse] = []
    
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    @State private var isLoadingChart = true
    @State private var isLoadingPhotos = true
    
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var showDeleteFolderAlert = false
    
    @State private var isSelectionMode = false
    @State private var selectedPhotosForDeletion: Set<String> = []
    @State private var isDeleting = false
    
    @State private var selectedFullScreenPhoto: String? = nil
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - GRAFICUL DE GREUTATE
                    VStack(alignment: .leading) {
                        Text("Weight Evolution (kg)").font(.headline).foregroundColor(.white)
                        
                        if isLoadingChart {
                            ProgressView().frame(height: 220).frame(maxWidth: .infinity)
                        } else if let data = chartData, !data.dates.isEmpty {
                            Chart {
                                ForEach(Array(zip(data.dates, data.weights).enumerated()), id: \.offset) { index, item in
                                    // Linia principală curbată
                                    LineMark(
                                        x: .value("Date", item.0),
                                        y: .value("Weight", item.1)
                                    )
                                    .foregroundStyle(Color.cyan)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    .interpolationMethod(.catmullRom)
                                    
                                    // Punctele cu TEXTUL DEASUPRA (Kg)
                                    PointMark(
                                        x: .value("Date", item.0),
                                        y: .value("Weight", item.1)
                                    )
                                    .foregroundStyle(Color.orange)
                                    .symbolSize(50)
                                    .annotation(position: .top, spacing: 4) {
                                        Text(String(format: "%.1f kg", item.1))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .chartYScale(domain: .automatic(includesZero: false))
                            .frame(height: 220)
                            .padding(.vertical, 8)
                        } else {
                            Text("No weight records yet.").foregroundColor(.gray).frame(height: 220)
                        }
                    }
                    .padding().background(Color(hex: "#1E1E1E")).cornerRadius(16)
                    
                    // MARK: - FOLDERE ȘI GALERIE FOTO
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // ROW 1: Titlu simplu
                        Text("Photo Progress").font(.headline).foregroundColor(.white)
                        
                        // ROW 2: Controalele pentru Foldere (Picker, Add, Delete)
                        HStack(spacing: 10) {
                            // Căsuța cu Picker-ul
                            HStack {
                                Image(systemName: "folder.fill").foregroundColor(.orange)
                                Picker("Folder", selection: $selectedFolder) {
                                    ForEach(foldersList, id: \.self) { folder in
                                        Text(folder).tag(folder)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.white) // Text alb
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            
                            // Butonul Adăugare (+)
                            Button(action: { showNewFolderAlert = true }) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.cyan)
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                            }
                            
                            // Butonul Ștergere (Gunoi)
                            Button(action: { showDeleteFolderAlert = true }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                            }
                        }
                        .onChange(of: selectedFolder) { _ in
                            isSelectionMode = false
                            selectedPhotosForDeletion.removeAll()
                            loadPhotos()
                        }
                        
                        // ROW 3: Butonul de Select Photos, poziționat deasupra galeriei
                        if !photosList.isEmpty {
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        isSelectionMode.toggle()
                                        selectedPhotosForDeletion.removeAll()
                                    }
                                }) {
                                    Text(isSelectionMode ? "Cancel Selection" : "Select Photos")
                                        .font(.subheadline.bold())
                                        .foregroundColor(isSelectionMode ? .gray : .orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Galeria Foto efectivă
                        if isLoadingPhotos {
                            ProgressView().frame(height: 100).frame(maxWidth: .infinity)
                        } else if photosList.isEmpty {
                            Text("No photos in this folder.").foregroundColor(.gray)
                        } else {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(photosList, id: \.id) { photo in
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: photo.photoUrl)) { img in
                                            img.resizable().scaledToFill()
                                        } placeholder: {
                                            Color.gray.opacity(0.3)
                                        }
                                        .frame(height: 100)
                                        .cornerRadius(8)
                                        .clipped()
                                        
                                        if isSelectionMode {
                                            let isSelected = selectedPhotosForDeletion.contains(photo.photoUrl)
                                            Rectangle()
                                                .fill(isSelected ? Color.cyan.opacity(0.4) : Color.black.opacity(0.2))
                                                .cornerRadius(8)
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(isSelected ? .cyan : .white)
                                                .font(.title2)
                                                .padding(6)
                                        }
                                    }
                                    .onTapGesture {
                                        if isSelectionMode {
                                            if selectedPhotosForDeletion.contains(photo.photoUrl) {
                                                selectedPhotosForDeletion.remove(photo.photoUrl)
                                            } else {
                                                selectedPhotosForDeletion.insert(photo.photoUrl)
                                            }
                                        } else {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedFullScreenPhoto = photo.photoUrl
                                            }
                                        }
                                    }
                                    .contextMenu {
                                        if !isSelectionMode {
                                            Button(role: .destructive, action: { deletePhoto(photo.photoUrl) }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Buton de Ștergere Multiplă
                        if isSelectionMode && !selectedPhotosForDeletion.isEmpty {
                            Button(action: deleteSelectedPhotos) {
                                if isDeleting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Delete Selected (\(selectedPhotosForDeletion.count))").bold()
                                }
                            }
                            .frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(12)
                            .disabled(isDeleting)
                        }
                        
                        // Buton de Upload Multiplu (Apare doar cand NU suntem in mod de selectie)
                        if !isSelectionMode {
                            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images, photoLibrary: .shared()) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Upload Photos")
                                }
                                .bold()
                                .frame(maxWidth: .infinity).padding().background(Color.cyan).foregroundColor(.black).cornerRadius(12)
                            }
                            .onChange(of: selectedPhotoItems) { newItems in
                                uploadSelectedPhotos(newItems)
                            }
                        }
                    }
                    .padding().background(Color(hex: "#1E1E1E")).cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Progress Gallery & Weight")
            .background(Color(hex: "#121212").ignoresSafeArea())
            .onAppear {
                loadChartData()
                loadFolders()
            }
            
            // MARK: - FULL SCREEN PHOTO OVERLAY
            if let fullScreenUrl = selectedFullScreenPhoto {
                ZStack {
                    Color.black.ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFullScreenPhoto = nil
                            }
                        }
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFullScreenPhoto = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding()
                            }
                        }
                        Spacer()
                        AsyncImage(url: URL(string: fullScreenUrl)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFit()
                            } else if phase.error != nil {
                                Text("Failed to load image").foregroundColor(.red)
                            } else {
                                ProgressView().tint(.white).scaleEffect(1.5)
                            }
                        }
                        Spacer()
                    }
                }
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .alert("New Folder", isPresented: $showNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) { newFolderName = "" }
            Button("Create") {
                let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    if !foldersList.contains(trimmed) {
                        foldersList.append(trimmed)
                    }
                    selectedFolder = trimmed
                    newFolderName = ""
                    loadPhotos()
                }
            }
        }
        .alert("Delete Folder", isPresented: $showDeleteFolderAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteCurrentFolder() }
        } message: {
            Text("Are you sure you want to delete '\(selectedFolder)' and all its contents? This cannot be undone.")
        }
    }
    
    // MARK: - API Calls
    private func loadChartData() {
        Task {
            do {
                chartData = try await APIService.shared.getClientProgressOverview(email: clientEmail)
                isLoadingChart = false
            } catch { isLoadingChart = false }
        }
    }
    
    private func loadFolders() {
        Task {
            do {
                let serverFolders = try await APIService.shared.getClientFolders(email: clientEmail)
                if !serverFolders.isEmpty {
                    foldersList = serverFolders
                    if !foldersList.contains(selectedFolder) {
                        selectedFolder = foldersList.first ?? "General Progress"
                    }
                }
                loadPhotos()
            } catch { isLoadingPhotos = false }
        }
    }
    
    private func loadPhotos() {
        isLoadingPhotos = true
        Task {
            do {
                photosList = try await APIService.shared.getPhotosByFolder(email: clientEmail, folder: selectedFolder)
                isLoadingPhotos = false
            } catch { isLoadingPhotos = false }
        }
    }
    
    private func deletePhoto(_ url: String) {
        Task {
            try? await APIService.shared.deletePhoto(photoUrl: url)
            loadPhotos()
        }
    }
    
    private func deleteSelectedPhotos() {
        isDeleting = true
        Task {
            do {
                try await APIService.shared.batchDeletePhotos(photoUrls: Array(selectedPhotosForDeletion))
                isSelectionMode = false
                selectedPhotosForDeletion.removeAll()
                isDeleting = false
                loadPhotos()
            } catch {
                isDeleting = false
            }
        }
    }
    
    private func deleteCurrentFolder() {
        isLoadingPhotos = true
        Task {
            do {
                try await APIService.shared.deleteFolder(email: clientEmail, folder: selectedFolder)
                loadFolders()
            } catch {
                isLoadingPhotos = false
            }
        }
    }
    
    private func uploadSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isLoadingPhotos = true
        Task {
            var uploadSuccesful = false
            for item in items {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data),
                       let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
                        _ = try await APIService.shared.uploadProgressPhoto(email: clientEmail, folder: selectedFolder, imageData: jpegData)
                        uploadSuccesful = true
                    }
                } catch {
                    print("Upload error: \(error)")
                }
            }
            await MainActor.run {
                selectedPhotoItems.removeAll()
                if uploadSuccesful { loadPhotos() } else { isLoadingPhotos = false }
            }
        }
    }
}
