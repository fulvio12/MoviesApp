
import UIKit

protocol FavoriteCellDelegate {
    func didTapFavoriteButton(movie: Movie) -> Bool
}

class MovieListCell: UITableViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var favoriteCellButton: UIButton!
    
    var delegate: FavoriteCellDelegate?
    var movieItem: Movie!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func setMovie(movie: Movie) {
        movieItem = movie
    }
    
    @IBAction func setFavorite(_ sender: UIButton) {
    
        guard let movieFavorited = delegate?.didTapFavoriteButton(movie: movieItem) else { return }
        
        if movieFavorited {
            favoriteCellButton.setImage(UIImage(imageLiteralResourceName: "favorite_full_icon"), for: .normal)
        } else {
            favoriteCellButton.setImage(UIImage(imageLiteralResourceName: "favorite_empty_icon"), for: .normal)
        }
    }
    
    
}
