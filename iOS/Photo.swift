struct Photo: ViewerItem {
    var id: Int

    init(id: Int) {
        self.id = id
    }

    static func constructElements() -> [ViewerItem] {
        var elements = [ViewerItem]()

        for i in 1..<60 {
            let photo = Photo(id: i)
            elements.append(photo)
        }

        return elements
    }
}
