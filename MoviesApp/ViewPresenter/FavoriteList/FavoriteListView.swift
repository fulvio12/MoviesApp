
import UIKit
import Foundation
import Disk

class FavoriteListViewController: UITableViewController {
        
    var retrievedFavorites: [Movie]?
    var filteredMovies: [Movie]?
    
    let searchController = UISearchController(searchResultsController: nil)
    
    let favoriteJSON = fileJSON.favorite.rawValue
    
    override func viewDidLoad() {
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UINib(nibName: "MovieListCell", bundle: nil), forCellReuseIdentifier: "MovieListCell")
        
        
        //Setup the Search Controller
        searchController.searchResultsUpdater = self
        if #available(iOS 9.1, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        } else {
            // Fallback on earlier versions
        }
        searchController.searchBar.placeholder = "Search Movie"
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            // Fallback on earlier versions
        }
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            retrievedFavorites = try Disk.retrieve(favoriteJSON, from: .applicationSupport, as: [Movie].self)
            if let retrievedMovies = retrievedFavorites {
                finishLoading(movies: retrievedMovies)
            }
            //dump(retrievedFavorites)
            
            
        } catch {
            print(error.localizedDescription)
        }
            
    }
    
    func finishLoading(movies: [Movie]) {
        self.retrievedFavorites = movies
        self.tableView.reloadData()
        // TODO: add callback for error!!!
    }
    
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText (_ searchText: String, scope: String = "All") {
        
        filteredMovies = (self.retrievedFavorites?.filter({ (movie: Movie) -> Bool in
            return movie.title.lowercased().contains(searchText.lowercased())
        }))!
        tableView.reloadData()
        
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredMovies?.count ?? 0
        } else {
            return retrievedFavorites?.count ?? 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MovieListCell = tableView.dequeueReusableCell(withIdentifier: "MovieListCell", for: indexPath) as! MovieListCell
        

        if isFiltering() {
            if let movie = filteredMovies?[indexPath.row] {
                showMovieIn(cell: cell, movie: movie)
                cell.setMovie(movie: movie)
            }
        } else {
            if let movie = retrievedFavorites?[indexPath.row] {
                showMovieIn(cell: cell, movie: movie)
                cell.setMovie(movie: movie)
            }
        }
        cell.delegate = self
        return cell
    }
    
    func showMovieIn(cell: MovieListCell, movie: Movie) {
        cell.titleLabel.text = movie.title
        cell.dateLabel.text = movie.localizedReleaseDate
        cell.genreLabel.text = movie.genresString
        
        cell.coverImageView.image = nil
        if let imageURL = MovieService.smallCoverUrl(movie: movie) {
            cell.coverImageView.load(url: imageURL)
        }
        
        if movie.favorited {
            cell.favoriteCellButton.setImage(UIImage(imageLiteralResourceName: "favorite_full_icon"), for: .normal)
        } else {
            cell.favoriteCellButton.setImage(UIImage(imageLiteralResourceName: "favorite_empty_icon"), for: .normal)
        }
    }
    
    //Slide to delete
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Unfavorite")
        { (action, sourceView, completionHandler) in
            var deleteMovie: Movie?
            deleteMovie = self.retrievedFavorites?[indexPath.row]
            
            if self.isFiltering() {
                if (self.filteredMovies?[indexPath.row]) != nil {
                    deleteMovie = self.filteredMovies![indexPath.row]
                    self.filteredMovies![indexPath.row].favorited = false
                }
                else { return }
            }
            if Disk.exists("favorite.json", in: .applicationSupport) {
                
                var fav = try? Disk.retrieve("favorite.json", from: .applicationSupport, as: [Movie].self)
                if (fav?.index{ $0.id == deleteMovie?.id}) != nil {
                    fav?.removeAll{$0.id == deleteMovie?.id }
                    try? Disk.save(fav, to: .applicationSupport, as: "favorite.json")
                    self.retrievedFavorites?.removeAll{$0.id == deleteMovie?.id }
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
                
            } else {
                completionHandler(false)
            }
            print("index path of delete: \(indexPath)")
        }
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete])
        return swipeActionConfig
    }
    
    
    // MARK: - UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "movieDetailSegue", sender: self)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let index = self.tableView.indexPathForSelectedRow?.row,
            let movie = self.retrievedFavorites?[index]
        {
            if let destination = segue.destination as? MovieDetailView {
                destination.setMovie(movie: movie)
            }
        }
    }
}

extension FavoriteListViewController: FavoriteCellDelegate {
    func didTapFavoriteButton(movie: Movie) -> Bool {
        print("Movie: \(movie.title)")
        
        if Disk.exists("favorite.json", in: .applicationSupport) {
            
            var fav = try? Disk.retrieve("favorite.json", from: .applicationSupport, as: [Movie].self)
            if (fav?.index{ $0.id == movie.id}) != nil {
                fav?.removeAll{$0.id == movie.id }
                try? Disk.save(fav, to: .applicationSupport, as: "favorite.json")
                self.retrievedFavorites?.removeAll{$0.id == movie.id }
            }
            if isFiltering() {
                self.filteredMovies!.removeAll{$0.id == movie.id }
            }
        }
        self.tableView.reloadData()
        return false
    }
}

extension FavoriteListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    
}
