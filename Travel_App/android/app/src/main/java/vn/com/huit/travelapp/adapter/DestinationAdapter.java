package vn.com.huit.travelapp.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import java.util.List;
import vn.com.huit.travelapp.R;
import vn.com.huit.travelapp.model.Destination;

public class DestinationAdapter extends RecyclerView.Adapter<DestinationAdapter.ViewHolder> {

    private List<Destination> destinations;
    private final OnItemClickListener itemClickListener;
    private final OnFavoriteClickListener favoriteClickListener;

    public interface OnItemClickListener {
        void onItemClick(Destination destination);
    }

    public interface OnFavoriteClickListener {
        void onFavoriteClick(Destination destination);
    }

    public DestinationAdapter(List<Destination> destinations,
            OnItemClickListener itemClickListener,
            OnFavoriteClickListener favoriteClickListener) {
        this.destinations = destinations;
        this.itemClickListener = itemClickListener;
        this.favoriteClickListener = favoriteClickListener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_destination, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Destination destination = destinations.get(position);
        holder.tvTitle.setText(destination.getTitle());
        holder.tvSubtitle.setText(destination.getSubtitle());
        holder.tvPrice.setText(String.format("%,.0f d", destination.getPrice()));

        Glide.with(holder.itemView.getContext())
                .load(destination.getImageUrl())
                .centerCrop()
                .placeholder(R.drawable.ic_launcher_background)
                .into(holder.ivThumbnail);

        holder.itemView.setOnClickListener(v -> itemClickListener.onItemClick(destination));
        holder.ivFavorite.setOnClickListener(v -> favoriteClickListener.onFavoriteClick(destination));
    }

    @Override
    public int getItemCount() {
        return destinations.size();
    }

    public void updateData(List<Destination> newDestinations) {
        this.destinations = newDestinations;
        notifyDataSetChanged();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView ivThumbnail;
        ImageView ivFavorite;
        TextView tvTitle;
        TextView tvSubtitle;
        TextView tvPrice;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            ivThumbnail = itemView.findViewById(R.id.ivThumbnail);
            ivFavorite = itemView.findViewById(R.id.ivFavorite);
            tvTitle = itemView.findViewById(R.id.tvTitle);
            tvSubtitle = itemView.findViewById(R.id.tvSubtitle);
            tvPrice = itemView.findViewById(R.id.tvPrice);
        }
    }
}
